
# Instalar paquetes
pkgs <- c("galah", "geodata", "terra", "dplyr")

# instala los que falten y cárgalos
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}



x <- show_all(atlases)
galah_config(atlas = "GBIF.es",
             email = Sys.getenv("ala_es_user"),
             password = Sys.getenv("ala_es_pw"))



(col.es <- (show_all_collections()))
(dat.es <- show_all_datasets())
(fields.es <- show_all_fields())



# Data call
test <- galah_call() |>
  galah_filter(year > 2022) |>
  galah_filter(basisOfRecord %in% c("MACHINE_OBSERVATION", "HUMAN_OBSERVATION")) |>
  galah_select(recordID, decimalLatitude, decimalLongitude, basisOfRecord) |>
  atlas_occurrences()




# 
test$basisOfRecord <- as.factor(test$basisOfRecord)
test$bor_code <- as.numeric(test$basisOfRecord)
v <- vect(test, geom=c("decimalLongitude","decimalLatitude"), crs="EPSG:4326")
r <- rast(ext(v), resolution = 0.05)
rr <- rasterize(
  v,
  r,
  field = "bor_code",
  fun = "range",      # majority category in each cell
  background = NA
)
# Category labels
levels(rr) <- data.frame(
  ID = 1:2,
  category = levels(test$basisOfRecord)
)

# Two colors
two_colors <- c("tomato", "royalblue")

plot(world, xlim = c(-20.39288, 5.946850), ylim = c(25.03948, 46.7483377),
     col="lightgray", border="gray40")
plot(
  rr, add = T,
  col = two_colors,
  plg = list(title = "Basis of Record", 
             x = "topleft", cex = 0.9)
)



## inset canaries

# 1. Canary raster
canary_bb <- ext(-18.5, -12.5, 27.5, 30.5)
rr_canary  <- crop(rr, canary_bb)

# 2. Main Iberia map
plot(rr, col=two_colors, legend=FALSE, mar=c(3,3,3,3))
plot(world, add=TRUE, border="grey40", col=NA)

# 3. Inset map (Canaries)
inset(0.05, 0.55, 0.35, 0.90, {
  
  plot(rr_canary,
       col = two_colors,
       legend = FALSE,
       axes = FALSE,
       box = FALSE)
  
  plot(world, add=TRUE, border="grey40", col=NA)
  box()
})





###############################################

# Add colors (raster??)
test$basisOfRecord <- as.factor(test$basisOfRecord)
niveles <- levels(test$basisOfRecord)
colores <- terrain.colors(length(niveles))
col_por_punto <- colores[test$basisOfRecord]

# Basemap
world <- geodata::world(path = ".")


# convertir a SpatVector
v <- vect(test, geom=c("decimalLongitude","decimalLatitude"), crs="EPSG:4326")

# crear raster de destino
r <- rast(ext(v), resolution = 0.05)  # ajusta resolución
rr <- rasterize(v, r, fun="count")
r


plot(world, xlim = c(-20.39288, 5.946850), ylim = c(25.03948, 46.7483377),
     col="lightgray", border="gray40",
     mar = c(4,4,4,8))

plot(rr, add = TRUE,
  alpha = 0.6,     # transparency so points + basemap remain visible
  main = "Observations 2023+",
  plg = list(
    title = "Count per cell",
    x = "right"
  )
)

# Too long -> vector data
# plot(v, add=TRUE, col=col_por_punto, pch=20, cex=0.1)

legend("bottomleft", 
       legend = niveles,
       col = colores,
       pch = 10,
       pt.cex = 1,
       title = "Basis of Record",
       bg = "white")



