library(codetools)
library(dplyr)
library(purrr)
library(tibble)
library(visNetwork)
library(scales)
library(htmlwidgets)

crear_mapa_dependencias <- function(
    pkg = "metagesToolkit",
    include_symbols = FALSE,
    n_columns = 6,
    output_file = "pkgdown/assets/dependency_map.html"
) {
  
  ns <- asNamespace(pkg)
  exports <- getNamespaceExports(ns)
  
  # ------------------------------------------------
  # Detectar paquete proveedor
  # ------------------------------------------------
  who_provides <- function(sym) {
    
    sym <- as.character(sym)
    
    core <- c("base","stats","utils","methods",
              "graphics","grDevices")
    
    for (p in core) {
      if (exists(sym, envir = asNamespace(p), inherits = FALSE))
        return(p)
    }
    
    for (p in loadedNamespaces()) {
      if (p == pkg) next
      if (exists(sym, envir = asNamespace(p), inherits = FALSE))
        return(p)
    }
    
    NA_character_
  }
  
  # ------------------------------------------------
  # Extraer relaciones
  # ------------------------------------------------
  edges_raw <- map_dfr(exports, function(fn) {
    
    f <- get(fn, envir = ns)
    
    gl <- tryCatch(findGlobals(f, merge = FALSE)$functions,
                   error = function(e) character(0))
    
    gl <- unique(gl)
    gl <- setdiff(gl,
                  c("{","(","[","[[","$","<-","=",
                    ":","::",":::","|>","%>%"))
    
    tibble(
      function_in_pkg = fn,
      symbol = gl,
      package = map_chr(gl, who_provides)
    )
  }) %>%
    filter(!is.na(package), package != pkg)
  
  # ------------------------------------------------
  # Construcción de nodos
  # ------------------------------------------------
  nodes_packages <- tibble(
    id = unique(edges_raw$package),
    label = id,
    group = "Package"
  )
  
  nodes_functions <- tibble(
    id = unique(edges_raw$function_in_pkg),
    label = id,
    group = "Function"
  )
  
  if (include_symbols) {
    
    # ID único por símbolo y paquete
    edges_raw <- edges_raw %>%
      mutate(symbol_id = paste0(package, "::", symbol))
    
    nodes_symbols <- edges_raw %>%
      distinct(symbol_id, symbol, package) %>%
      transmute(
        id = symbol_id,
        label = symbol,
        group = "Symbol"
      )
    
    edges <- bind_rows(
      tibble(from = edges_raw$package,
             to   = edges_raw$symbol_id),
      tibble(from = edges_raw$symbol_id,
             to   = edges_raw$function_in_pkg)
    ) %>% distinct()
    
    nodes <- bind_rows(nodes_packages,
                       nodes_symbols,
                       nodes_functions)
    
  } else {
    
    edges <- tibble(
      from = edges_raw$package,
      to   = edges_raw$function_in_pkg
    ) %>% distinct()
    
    nodes <- bind_rows(nodes_packages,
                       nodes_functions)
  }
  
  # ------------------------------------------------
  # Tamaño dinámico por grado
  # ------------------------------------------------
  degree <- table(c(edges$from, edges$to))
  nodes$size <- as.numeric(degree[nodes$id])
  nodes$size[is.na(nodes$size)] <- 1
  nodes$size <- rescale(nodes$size, to = c(15, 45))
  
  # ------------------------------------------------
  # Layout GRID ordenado (pero movible)
  # ------------------------------------------------
  posicionar <- function(df, y_base) {
    
    df %>%
      arrange(id) %>%
      mutate(
        col = (row_number() - 1) %% n_columns,
        row = floor((row_number() - 1) / n_columns),
        x = col * 250,
        y = y_base + row * 140
      )
  }
  
  if (include_symbols) {
    
    nodes_packages  <- posicionar(nodes_packages, 0)
    nodes_symbols   <- posicionar(nodes_symbols, 600)
    nodes_functions <- posicionar(nodes_functions, 1200)
    
    nodes <- bind_rows(nodes_packages,
                       nodes_symbols,
                       nodes_functions)
    
  } else {
    
    nodes_packages  <- posicionar(nodes_packages, 0)
    nodes_functions <- posicionar(nodes_functions, 600)
    
    nodes <- bind_rows(nodes_packages,
                       nodes_functions)
  }
  
  # ------------------------------------------------
  # Crear grafo
  # ------------------------------------------------
  graph <- visNetwork(nodes, edges) %>%
    visGroups(groupname = "Package",
              color = list(background = "#F44336"),
              font = list(size = 18)) %>%
    visGroups(groupname = "Symbol",
              color = list(background = "#2196F3"),
              font = list(size = 14)) %>%
    visGroups(groupname = "Function",
              color = list(background = "#4CAF50"),
              font = list(size = 18)) %>%
    visEdges(arrows = "to", smooth = TRUE) %>%
    visPhysics(enabled = FALSE) %>%
    visOptions(highlightNearest = TRUE,
               nodesIdSelection = TRUE)
  
  
  tmp <- tempfile(fileext = ".html")
  
  saveWidget(
    graph,
    file = tmp,
    selfcontained = TRUE
  )
  
  file.copy(tmp, output_file, overwrite = TRUE)
  
  return(graph)
}

crear_mapa_dependencias()