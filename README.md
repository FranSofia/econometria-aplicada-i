# Econometría aplicada I

Sitio web del curso "Econometría aplicada I" del Magíster en Análisis Económico de la Universidad de Chile en su modalidad weekend.

**Sitio web:** <https://fransofia.github.io/econometria-aplicada-i/>

## Descripción

Este repositorio y sitio web está enfocado a documentar los apuntes y trabajos que realizo como estudiante en el curso "Econometría aplicada I" del Magíster en Análisis Económico en su versión *weekend* (MAE wk) de la Universidad de Chile (UCH).

## Contenido

1.  **Métodos Causales:** Endogeneidad, Evaluación Experimental, Selección en Observables y Regresiones
2.  **Variables Instrumentales (IV):** Identificación y estimación.
3.  **Regresión Discontinua (RDD):** Diseños nítidos y borrosos. Comienzo de DiD
4.  **Datos de Panel, Efectos Fijos, Diferencias en Diferencias (DiD) y Estudios de Eventos**.
5.  **Matching**

## Estructura del proyecto

```         
econometria-aplicada-i/
├── _quarto.yml                              # Configuración 
├── index.qmd                                # Portada
├── syllabus.qmd                             # Programa 
├── styles.scss                              # Estilo "Metropolis" 
├── .gitignore                               # Para no bloquear el repo con datos pesados
└── sesiones/                                # Carpeta principal de trabajo
    ├── data/                                # Aquí van los .dta o .rds (Local)
    ├── 01-causalidad.qmd                    # Sesión 1
    ├── 02-iv.qmd                            # Sesión 2
    ├── 03-rdd.qmd                           # Sesión 3
    ├── 04-datapanel-did-eventstudy.qmd      # Sesión 4
    └── 05-matching.qmd                      # Sesión 5
```

## Tecnologías

Este sitio está construido con:

-   [Quarto](https://quarto.org/) - Sistema de publicación científica y técnica
-   [R](https://www.r-project.org/) - Lenguaje de programación estadístico
-   [GitHub Pages](https://pages.github.com/) - Hosting gratuito

2.  Abre el proyecto en RStudio

3.  Instala Quarto desde [quarto.org](https://quarto.org/docs/get-started/)

4.  Previsualiza el sitio:

``` bash
quarto preview
```

5.  Renderiza el sitio completo:

``` bash
quarto render
```

## Licencia

Este material está bajo licencia [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

## Contacto

\[Fran Sofía Núñez Rebolledo\]\
\[fnunezre\@fen.uchile.lc\]\
\[Universidad de Chile e Instituto Nacional de Estadísticas\]

------------------------------------------------------------------------

**Semestre:** Primavera II: 2025-26
