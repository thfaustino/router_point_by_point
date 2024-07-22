# Instalar pacotes necessários (se ainda não estiverem instalados)
install.packages(c("osmdata", "sf", "stplanr", "osrm"))

# Carregar pacotes
library(osmdata)
library(sf)
library(stplanr)
library(osrm)

# Definir pontos de origem e destino (exemplo: coordenadas de latitude e longitude)
origem <- c(-43.864391, -16.719863) # MONTES CLAROS, MG
destino <- c(-43.801038, -16.677943) # MONTES CLAROS, MG

# Converter pontos em objetos sf
origem_sf <- st_point(origem) %>% 
  st_sfc(crs = 4326) %>% 
  st_sf()
destino_sf <- st_point(destino) %>% 
  st_sfc(crs = 4326) %>% 
  st_sf()

# Obter rota usando OSRM
rota <- osrmRoute(src = origem_sf, dst = destino_sf, returnclass = "sf")
st_write(rota,'rota.shp')