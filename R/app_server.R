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
    test_data[[input$organism]]
  })
  genome_versions <- reactive({
    req(input$organism)
    sort_genomes(organism_data()$stats)
  })
  selected_genome <- reactive({
    req(input$version)
    req(genome_versions())
    genome_versions()[[input$version]] %>%
      genome_consensus()
  })
  output$contents <- renderEcharts4r({
    req(selected_genome())
    chrom_vis(selected_genome())
  })
  output$donut <- renderEcharts4r({
    req(organism_data())
    species_donut(organism_data()$metadata)
  })
  output$phylo <- renderPlot({
    req(organism_data())
    plot(tax_tree(organism_data()$metadata))
  })
}
