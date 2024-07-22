# libraries
library(osmdata)
library(sf)
library(stplanr)
library(osrm)
library(RPostgres)
library(readxl)
library(dplyr)
library(stringr)

#stops by line
secoes_linha <- read_excel(file.choose())
linhas<-read_excel(file.choose())
linhas<-linhas[!grepl("ARQUIV",linhas$Nome),]

#connecting with GEPPI database
dsn_database = "GEPPI"
dsn_hostname = "****"  
dsn_port = "****"
dsn_uid = "***"  # insert user"
dsn_pwd = "***"  # insert key"

con <- dbConnect(RPostgres::Postgres(),
                 dbname = dsn_database,
                 host = dsn_hostname, port = 5432,
                 user = dsn_uid, password = dsn_pwd)
rm(dsn_database,dsn_hostname,dsn_port,dsn_uid,dsn_pwd)
stops<-st_read(con,query="SELECT * FROM transporte_intermunicipal.gtfs_stops")
dbDisconnect(con)
rm(con)

#list of bus lines
line<-linhas$Linha %>% unique()

for(j in 1:length(line)){
  tryCatch({
    pontos <- filter(secoes_linha, secoes_linha$`Número Linha` == line[j])
    pontos$id <- c(1:nrow(pontos))
    
    i <- 1
    for(i in 1:(nrow(pontos)-1)){
      origem_sf <- filter(stops, stop_id == pontos$`Código Ponto`[i])
      destino_sf <- filter(stops, stop_id == pontos$`Código Ponto`[i+1])
      rota_trecho <- osrmRoute(src = origem_sf, dst = destino_sf, overview = 'full')
      rota_trecho$origin<-origem_sf$stop_id[1]
      rota_trecho$destination<-destino_sf$stop_id[1]
      if(i == 1){
        rota_ida <- rota_trecho
      } else {
        rota_ida <- rbind(rota_ida, rota_trecho)
      }
    }
    
    rota_ida$sentido <- 1
    pontos <- arrange(pontos, desc(id))
    
    for(i in 1:(nrow(pontos)-1)){
      origem_sf <- filter(stops, stop_id == pontos$`Código Ponto`[i])
      destino_sf <- filter(stops, stop_id == pontos$`Código Ponto`[i+1])
      rota_trecho <- osrmRoute(src = origem_sf, dst = destino_sf, overview = 'full')
      rota_trecho$origin<-origem_sf$stop_id[1]
      rota_trecho$destination<-destino_sf$stop_id[1]
      if(i == 1){
        rota_volta <- rota_trecho
      } else {
        rota_volta <- rbind(rota_volta, rota_trecho)
      }
    }
    
    rota_volta$sentido <- 2
    rota <- rbind(rota_ida, rota_volta)
    rota$line <- line[j]
    st_write(rota, str_c(line[j], '.shp'))
    
    if(j == 1){
      rota_completa <- rota
    } else {
      rota_completa <- rbind(rota, rota_completa)
    }
  }, error = function(e){
    cat("Erro na linha", line[j], "- pulando para a próxima iteração\n")
  })
}

st_write(rota_completa,'rota_completa.shp')
