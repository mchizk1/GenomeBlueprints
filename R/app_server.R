#=======================================
# THIS IS CURRENTLY JUST A PLACEHOLDER
#=======================================

#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @import leaflet
#' @import ggiraph
#' @importFrom echarts4r renderEcharts4r
#' @noRd
app_server <- function(input, output, session) {
  output$alluvial_plot <- renderGirafe({
    p <- alluvial_plot(input$genome_filter)
    girafe(ggobj = p)
  })
  
  output$chr_map <- renderPlot({
    chromosome_map(input$focused_genome)
  })
}
