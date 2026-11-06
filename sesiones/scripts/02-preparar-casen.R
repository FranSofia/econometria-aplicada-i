# =============================================================================
# Sesión 2 · Preparación de la base CASEN para el ejemplo shift-share
# -----------------------------------------------------------------------------
# Este script se corre UNA vez, en un PC que tenga las bases CASEN completas
# (2015, 2017 y 2022, formato Stata). Produce una base recortada y liviana,
# `sesiones/datos-procesados/casen_migracion.rds`, que sí se versiona en git y
# es la que usa `02-iv.qmd`.
#
# Las bases originales se descargan desde el Observatorio Social del
# Ministerio de Desarrollo Social y Familia:
# https://observatorio.ministeriodesarrollosocial.gob.cl/encuesta-casen
#
# Uso (desde la carpeta raíz del repo, en la consola de R):
#   ruta_casen <- "C:/ruta/a/las/bases"   # carpeta con los tres .dta
#   source("sesiones/scripts/02-preparar-casen.R")
# =============================================================================

library(tidyverse)
library(haven)

if (!exists("ruta_casen")) stop("Defina `ruta_casen` con la carpeta de las bases CASEN.")

archivos <- c(
  "2015" = file.path(ruta_casen, "Casen 2015.dta"),
  "2017" = file.path(ruta_casen, "Casen 2017.dta"),
  "2022" = file.path(ruta_casen, "Casen 2022.dta")
)
stopifnot(all(file.exists(archivos)))

# Variables que se leen de cada base (leer solo estas ahorra mucha memoria)
vars_casen <- c("edad", "sexo", "r1b", "activ", "esc", "o10", "ytrabajocor",
                "region", "rama1")

# --- Armonización de sectores (CIIU Rev. 3 en 2015-2017, Rev. 4 en 2022) ------
armonizar_sector <- function(rama, anio) {
  if (anio %in% c(2015, 2017)) {
    case_when(
      rama %in% 1:2  ~ "Agricultura y pesca",
      rama == 3      ~ "Minería",
      rama == 4      ~ "Manufactura",
      rama == 5      ~ "Suministros básicos",
      rama == 6      ~ "Construcción",
      rama == 7      ~ "Comercio",
      rama == 8      ~ "Hoteles y restaurantes",
      rama == 9      ~ "Transporte y comunicaciones",
      rama == 10     ~ "Servicios financieros",
      rama == 11     ~ "Servicios empresariales",
      rama == 12     ~ "Administración pública",
      rama == 13     ~ "Enseñanza",
      rama == 14     ~ "Salud",
      rama == 15     ~ "Otros servicios",
      rama == 16     ~ "Hogares como empleadores",
      rama == 17     ~ "Organizaciones extraterritoriales"
    )
  } else {
    case_when(
      rama == 1             ~ "Agricultura y pesca",
      rama == 2             ~ "Minería",
      rama == 3             ~ "Manufactura",
      rama %in% 4:5         ~ "Suministros básicos",
      rama == 6             ~ "Construcción",
      rama == 7             ~ "Comercio",
      rama %in% c(8, 10)    ~ "Transporte y comunicaciones",
      rama == 9             ~ "Hoteles y restaurantes",
      rama == 11            ~ "Servicios financieros",
      rama %in% 12:14       ~ "Servicios empresariales",
      rama == 15            ~ "Administración pública",
      rama == 16            ~ "Enseñanza",
      rama == 17            ~ "Salud",
      rama %in% 18:19       ~ "Otros servicios",
      rama == 20            ~ "Hogares como empleadores",
      rama == 21            ~ "Organizaciones extraterritoriales"
    )
  }
}

# --- Limpieza de cada año -----------------------------------------------------
procesar_casen <- function(archivo, anio) {
  read_dta(archivo, col_select = all_of(vars_casen)) |>
    zap_labels() |>
    mutate(across(everything(), as.numeric)) |>
    filter(between(edad, 18, 60)) |>
    transmute(
      anio,
      migrante   = as.numeric(r1b == 3),
      ocupado    = as.numeric(activ == 1),
      esc        = if_else(esc > 30, NA_real_, esc),
      alta_calif = as.numeric(esc >= 13),
      horas      = if_else(o10 <= 0 | o10 > 168, NA_real_, o10),
      ln_salario_hora = log(ytrabajocor / (horas * 4.345)),
      mujer  = as.numeric(sexo == 2),
      exper  = pmax(0, edad - coalesce(esc, 0) - 6),
      exper2 = exper^2,
      region = if_else(region == 16, 8, region),     # Ñuble vuelve a Biobío
      sector = armonizar_sector(rama1, anio)
    )
}

casen <- imap_dfr(archivos, ~ procesar_casen(.x, as.numeric(.y)))

ocupados <- casen |>
  filter(ocupado == 1, !is.na(sector), !is.na(alta_calif))

# --- Variable endógena: tasa de migrantes por celda sector-región-año ---------
celdas <- ocupados |>
  group_by(anio, region, sector) |>
  summarise(
    n_ocupados  = n(),
    n_migrantes = sum(migrante),
    tasa_migrantes = n_migrantes / n_ocupados,
    .groups = "drop"
  )

# --- Instrumento shift-share --------------------------------------------------
# Participaciones: migrantes de cada nivel educativo sobre ocupados de la celda, en 2015
participaciones <- ocupados |>
  filter(anio == 2015) |>
  group_by(region, sector) |>
  mutate(pob_sr_2015 = n()) |>
  group_by(region, sector, alta_calif, pob_sr_2015) |>
  summarise(m_sr_e_2015 = sum(migrante), .groups = "drop") |>
  mutate(participacion = m_sr_e_2015 / pob_sr_2015)

# Shocks: crecimiento nacional de migrantes ocupados de cada nivel educativo
shocks <- ocupados |>
  filter(migrante == 1) |>
  count(anio, alta_calif, name = "m_e_t") |>
  group_by(alta_calif) |>
  mutate(shock = m_e_t / m_e_t[anio == 2015]) |>
  ungroup()

instrumento <- participaciones |>
  inner_join(shocks, by = "alta_calif", relationship = "many-to-many") |>
  group_by(anio, region, sector) |>
  summarise(z_shift_share = sum(participacion * shock), .groups = "drop")

# --- Base final: trabajadores nativos ocupados con salario ---------------------
casen_migracion <- ocupados |>
  filter(migrante == 0, is.finite(ln_salario_hora)) |>
  select(anio, region, sector, ln_salario_hora, alta_calif, mujer, exper, exper2) |>
  left_join(celdas, by = c("anio", "region", "sector")) |>
  left_join(instrumento, by = c("anio", "region", "sector")) |>
  mutate(region = as.integer(region), anio = as.integer(anio))

# Resumen agregado de migrantes por año (para el gráfico descriptivo)
resumen_migrantes <- casen |>
  group_by(anio) |>
  summarise(
    n_encuestados   = n(),
    pct_migrantes   = 100 * mean(migrante, na.rm = TRUE),
    pct_alta_calif_migrantes = 100 * mean(alta_calif[migrante == 1], na.rm = TRUE),
    .groups = "drop"
  )

dir.create("sesiones/datos-procesados", showWarnings = FALSE)
saveRDS(
  list(trabajadores = casen_migracion, resumen = resumen_migrantes),
  "sesiones/datos-procesados/casen_migracion.rds",
  compress = "xz"
)

message("Base guardada: ", nrow(casen_migracion), " trabajadores nativos, ",
        n_distinct(casen_migracion[c("anio", "region", "sector")]), " celdas.")
