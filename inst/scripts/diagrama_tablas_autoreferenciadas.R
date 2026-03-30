# Funciones para crear diagramas de relaciones internas en tablas autoreferenciadas

library(metagesToolkit)
library(DBI)


# Conectar a MetaGES
con <- conectar_metages()$con

# Crear dataframe con tabla a explorar
types <- dbGetQuery(con, "SELECT types_id, types_fk, name, name_eng
                          FROM metages_types")

#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
#-----VISNETWORK-------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------

library(visNetwork)
library(dplyr)
library(DBI)


plot_types_vis <- function(df,
                           id_col = "types_id",
                           parent_col = "types_fk",
                           label_col = "name",
                           root_value = 0) {
  
  df <- df %>%
    mutate(
      id = as.character(.data[[id_col]]),
      parent = as.character(.data[[parent_col]]),
      label = as.character(.data[[label_col]])
    )
  
  # calcular nivel jerárquico
  level_map <- setNames(rep(NA_integer_, nrow(df)), df$id)
  
  get_level <- function(node_id) {
    if (!is.na(level_map[[node_id]])) return(level_map[[node_id]])
    
    row <- df %>% filter(id == node_id)
    if (nrow(row) == 0) return(NA_integer_)
    
    parent <- row$parent[[1]]
    
    if (is.na(parent) || parent == as.character(root_value)) {
      level_map[[node_id]] <<- 1L
    } else {
      level_map[[node_id]] <<- get_level(parent) + 1L
    }
    
    level_map[[node_id]]
  }
  
  levels <- vapply(df$id, get_level, integer(1))
  
  nodes <- df %>%
    transmute(
      id = id,
      label = label,
      title = paste0(
        "<b>ID:</b> ", id,
        "<br><b>Nombre:</b> ", label,
        if ("name_eng" %in% names(df)) paste0("<br><b>EN:</b> ", name_eng) else ""
      ),
      level = levels
    )
  
  edges <- df %>%
    filter(!is.na(parent), parent != as.character(root_value)) %>%
    transmute(
      from = parent,
      to = id
    )
  
  visNetwork(nodes, edges, height = "900px", width = "100%") %>%
    visHierarchicalLayout(
      direction = "LR",
      sortMethod = "directed",
      levelSeparation = 300,
      nodeSpacing = 10,
      treeSpacing = 260,
      blockShifting = TRUE,
      edgeMinimization = TRUE,
      parentCentralization = TRUE
    ) %>%
    visNodes(
      shape = "box",
      margin = 2,
      font = list(size = 4)
    ) %>%
    visEdges(
      arrows = list(to = list(enabled = TRUE, scaleFactor = 0.2)),
      smooth = TRUE
    ) %>%
    visInteraction(
      navigationButtons = TRUE,
      zoomView = TRUE,
      dragView = TRUE,
      dragNodes = TRUE
    ) %>%
    visPhysics(enabled = FALSE)
}

plot_types_vis(types)


#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
#-----CollapsibleTree-------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------

library(collapsibleTree)
library(dplyr)
library(purrr)
library(DBI)


build_paths <- function(df,
                        id_col = "types_id",
                        parent_col = "types_fk",
                        label_col = "name",
                        root_value = 0) {
  
  df <- df %>%
    mutate(
      id = as.character(.data[[id_col]]),
      parent = as.character(.data[[parent_col]]),
      label = as.character(.data[[label_col]])
    ) %>%
    select(id, parent, label)
  
  parent_map <- setNames(df$parent, df$id)
  label_map  <- setNames(df$label, df$id)
  
  get_path <- function(node_id) {
    path <- character()
    current <- node_id
    
    repeat {
      path <- c(label_map[[current]], path)
      parent <- parent_map[[current]]
      
      if (is.na(parent) || parent == as.character(root_value) || !(parent %in% names(parent_map))) {
        break
      }
      
      current <- parent
    }
    
    path
  }
  
  internal_nodes <- unique(df$parent[!is.na(df$parent) & df$parent != as.character(root_value)])
  leaf_ids <- df$id[!(df$id %in% internal_nodes)]
  
  paths <- lapply(leaf_ids, get_path)
  max_depth <- max(lengths(paths))
  
  mat <- t(vapply(
    paths,
    function(p) {
      c(p, rep(NA_character_, max_depth - length(p)))
    },
    FUN.VALUE = character(max_depth)
  ))
  
  out <- as.data.frame(mat, stringsAsFactors = FALSE)
  names(out) <- paste0("level_", seq_len(ncol(out)))
  
  out <- out[, colSums(!is.na(out)) > 0, drop = FALSE]
  rownames(out) <- NULL
  
  out
}

plot_types_collapsible <- function(df,
                                   id_col = "types_id",
                                   parent_col = "types_fk",
                                   label_col = "name",
                                   root_value = 0,
                                   font_size = 8,
                                   link_length = 220,
                                   collapsed = TRUE,
                                   height = 1200) {
  
  paths_df <- build_paths(
    df = df,
    id_col = id_col,
    parent_col = parent_col,
    label_col = label_col,
    root_value = root_value
  )
  
  hierarchy_cols <- names(paths_df)
  
  collapsibleTree(
    df = paths_df,
    hierarchy = hierarchy_cols,
    root = "types",
    zoomable = TRUE,
    collapsed = collapsed,
    fontSize = font_size,
    linkLength = link_length,
    width = "100%",
    height = height
  )
}

plot_types_collapsible(
  types,
  font_size = 7,
  link_length = 200,
  collapsed = F,
  height = 1300
)
