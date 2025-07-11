
#' Visualize Chromosome Data
#' 
#' This function creates a horizontal bar chart to visualize chromosome lengths from a given dataset.
#' 
#' @param chrom_data A data frame containing chromosome data with columns for chromosome names and their lengths.
#' @return A horizontal bar chart visualizing chromosome lengths.
#' @import echarts4r
#' @export

chrom_vis <- function(chrom_data){
  chrom_data |>
    e_charts(chromosome) |>
    e_bar(value, 
          itemStyle = list(
            borderRadius = c(10, 10, 10, 10)  # top-left, top-right, bottom-right, bottom-left
          )) |>
    e_flip_coords() |>
    e_theme("infographic") |>
    e_tooltip() |>
    e_x_axis(name = "Length (bp)") |> 
    e_y_axis(name = "Chromosome") 
}

#' Visualize NCBI Assemblies by Species
#' 
#' This function creates a donut chart to visualize the number of NCBI assemblies grouped by species.
#' @param genome_metadata A data frame containing genome metadata with a column for species.
#' @return A donut chart visualizing the number of NCBI assemblies by species.
#' @import echarts4r
#' @import dplyr 
#' @export

species_donut <- function(genome_metadata){
  total <- nrow(genome_metadata)
  genome_metadata |>
    group_by(species) |>
    summarise(count = n()) |>
    e_charts(species) |>
    e_pie(serie = count, 
          name = "NCBI Assemblies",
          radius = c("40%", "70%")) |>
    e_legend(show = FALSE) |>
    e_tooltip() |>
    e_theme("infographic") |>
    e_title("NCBI Assemblies") |>
    e_graphic_g(
      elements = list(
        list(
          type = "text",
          left = "center",
          top = "middle",
          style = list(
            text = paste0(total),
            textAlign = "center",
            fill = "#333",
            fontSize = 20))))
}
