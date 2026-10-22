# ==============================================================================
# Dashboard Ejecutivo Institucional (Shiny) - Universidad Nova
# Autor: Equipo de Gobierno y Analítica de Datos
# ==============================================================================

library(shiny)
library(ggplot2)
library(dplyr)
library(DBI)
library(RSQLite)

# Conexión al DWH corporativo simulado
conn <- dbConnect(RSQLite::SQLite(), "dwh_universidad_nova.db")
datos_dwh <- dbGetQuery(conn, "
  SELECT d.facultad, h.promedio_ponderado, h.asistencia_lms_pct 
  FROM Hechos_Rendimiento h
  JOIN Dim_Estudiante d ON h.id_estudiante = d.id_estudiante;
")
dbDisconnect(conn)

# Definición de la interfaz de usuario (UI)
ui <- fluidPage(
  titlePanel("Universidad Nova - Panel de Gobierno y Analítica de Datos"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("facultad_sel", "Seleccione Facultad:",
                  choices = c("Todas", unique(datos_dwh$facultad))),
      sliderInput("min_promedio", "Filtrar por Promedio Mínimo:",
                  min = 2.0, max = 5.0, value = 3.0, step = 0.1)
    ),
    
    mainPanel(
      fluidRow(
        column(6, plotOutput("grafico_promedios")),
        column(6, plotOutput("grafico_asistencia"))
      )
    )
  )
)

# Definición de la lógica del servidor (Server)
server <- function(input, output, session) {
  
  datos_filtrados <- reactive({
    df <- datos_dwh
    if (input$facultad_sel != "Todas") {
      df <- df %>% filter(facultad == input$facultad_sel)
    }
    df <- df %>% filter(promedio_ponderado >= input$min_promedio)
    return(df)
  })
  
  output$grafico_promedios <- renderPlot({
    df <- datos_filtrados()
    ggplot(df, aes(x = facultad, y = promedio_ponderado, fill = facultad)) +
      geom_boxplot(alpha = 0.7) +
      theme_minimal() +
      labs(title = "Distribución de Promedios Ponderados por Facultad",
           x = "Facultad", y = "Promedio Ponderado") +
      theme(legend.position = "none")
  })
  
  output$grafico_asistencia <- renderPlot({
    df <- datos_filtrados()
    ggplot(df, aes(x = asistencia_lms_pct)) +
      geom_histogram(bins = 20, fill = "steelblue", color = "white") +
      theme_minimal() +
      labs(title = "Histograma de Asistencia a Plataforma LMS (%)",
           x = "Porcentaje de Asistencia LMS", y = "Frecuencia Estudiantil")
  })
}

# Ejecución de la aplicación Shiny
shinyApp(ui = ui, server = server)
