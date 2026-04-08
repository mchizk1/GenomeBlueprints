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
  alluvial_plot <- function(genome_names) {
    genomes <- if (length(genome_names) > 0) genome_names else "GenomeA"
    mock_map <- data.frame(
      genome = rep(genomes, each = 3),
      chromosome = rep(c("Chr1", "Chr2", "Chr3"), times = length(genomes)),
      HOM = rep(c("1", "2", "3"), times = length(genomes)),
      HOM_chr = rep(c("1", "1", "2"), times = length(genomes)),
      chr = rep(c("Chr1", "Chr2", "Chr3"), times = length(genomes))
    )
    plot_mapping(mock_map, "Demo")
  }

  chromosome_map <- function(genome_names) {
    genome <- if (length(genome_names) > 0) genome_names[[1]] else "GenomeA"
    vals <- data.frame(
      chromosome = factor(c("Chr1", "Chr2", "Chr3"), levels = c("Chr1", "Chr2", "Chr3")),
      value = c(150, 110, 90)
    )
    barplot(
      vals$value,
      names.arg = vals$chromosome,
      las = 1,
      col = "#3b82f6",
      main = paste(genome, "Chromosome Lengths (Demo)"),
      xlab = "Length (bp, scaled)"
    )
  }

  output$alluvial_plot <- renderGirafe({
    p <- alluvial_plot(input$focused_genome)
    girafe(ggobj = p)
  })

  output$chr_map <- renderPlot({
    chromosome_map(input$focused_genome)
  })
}
