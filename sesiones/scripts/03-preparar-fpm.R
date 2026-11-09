# =============================================================================
# Sesión 3 · Base recortada de Litschig y Morrison (2013)
# -----------------------------------------------------------------------------
# Lee los datos de replicación originales (`fpm1980_1991_final.dta`, disponibles
# en el material del artículo, doi:10.1257/app.5.4.206) y guarda solo las
# variables y municipios que usa `03-rdd.qmd`.
#
# Uso (desde la carpeta raíz del repo):
#   ruta_fpm <- "C:/ruta/a/fpm1980_1991_final.dta"
#   source("sesiones/scripts/03-preparar-fpm.R")
# =============================================================================

library(tidyverse)
library(haven)

if (!exists("ruta_fpm")) stop("Defina `ruta_fpm` con la ruta al archivo .dta original.")

fpm <- read_dta(ruta_fpm) |>
  zap_labels() |>
  filter(!is.na(pscore)) |>            # municipios cercanos a los cortes 1 a 3
  transmute(
    municipio = ibgeufmuni,
    estado = state,
    corte = seg,                        # 1, 2 o 3
    pscore,                             # población normalizada (miles), corte en 0
    # Primera etapa: log de transferencias FPM per cápita 1982-1985
    log_fpm_pc = l_r_fpm82_85_m_pcap,
    # Resultados en 1991 (tablas 5 y 6 del artículo)
    escolaridad_9_18 = educ9_1891,
    escolaridad_19_28 = educ19_2891,
    alfabetizacion_9_18 = literacy9_1891,
    alfabetizacion_19_28 = literacy19_2891,
    pobreza_91 = poverty91,
    reeleccion = re_elect_s,
    # Características de 1980, previas al tratamiento
    ingreso_pc_80 = pcapincome80,
    pobreza_80 = poverty80,
    analfabetismo_80 = illiteracy15_a80,
    urbano_80 = urban80,
    mortalidad_infantil_80 = infantmortality80
  )

dir.create("sesiones/datos-procesados", showWarnings = FALSE)
saveRDS(fpm, "sesiones/datos-procesados/fpm_litschig_morrison.rds", compress = "xz")
message("Base guardada: ", nrow(fpm), " municipios.")
