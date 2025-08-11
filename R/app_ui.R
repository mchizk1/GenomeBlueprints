#=======================================
# THIS IS CURRENTLY JUST A PLACEHOLDER
#=======================================

#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import bslib
#' @noRd

# === Sample data for dropdown ===
available_genomes <- c("GenomeA", "GenomeB", "GenomeC", "GenomeD")
# === UI ===
app_ui <- page_fluid(
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",  # or "simplex", "minty", "yeti", etc.
    base_font = font_google("Open Sans"),
    heading_font = font_google("Roboto Slab")
  ),
  
  layout_sidebar(
    sidebar = sidebar(
      h4("Genome Filters"),
      selectInput("genus_filter", "Genus",
                  choices = c("All", "Genus1", "Genus2", "Genus3"),
                  selected = "All"),
      selectInput("species_filter", "Species",
                  choices = c("All", "Species1", "Species2", "Species3"),
                  selected = "All"),
      tags$hr(),
      h4("Chromosome View"),
      selectInput("focused_genome", NULL,
                  choices = available_genomes,
                  selected = available_genomes[1],
                  multiple = TRUE)
    ),
    
    layout_column_wrap(
      width = 1,
      card(
        full_screen = TRUE,
        card_header("Genome Lexicon"),
        girafeOutput("alluvial_plot", height = "500px")
      ),
      card(
        full_screen = TRUE,
        card_header("Scaled Chromosome Map"),
        plotOutput("chr_map", height = "600px")
      )
    )
  )
)

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "genomebluepRints"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
