
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