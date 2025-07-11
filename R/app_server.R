#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @import leaflet
#' @importFrom echarts4r renderEcharts4r
#' @noRd
app_server <- function(input, output, session) {
  # create a reactive that updates when input$organism changes
  organism_data <- reactive({
    req(input$organism)
    # Simulate fetching data based on the selected organism
    ncbi_genome_stats(input$organism)
  })
  output$contents <- renderEcharts4r({
    req(organism_data())
    chrom_vis(organism_data())
  })
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles("CartoDB.Positron") %>% 
      addCircles(lng = c(-122, 170), lat = c(37, -45), 
                 label = c("San Francisco", "New Zealand"), 
                 color = "red", radius = 500000) %>%
      addPolygons(lng = c(-80, -70, -60), lat = c(10, 20, 10),
                  fillColor = "blue", weight = 1, opacity = 0.5)
  })
}
