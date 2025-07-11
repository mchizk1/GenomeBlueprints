#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic
    fluidPage(
      titlePanel("Genome Blueprints"),
      fluidRow(
        # Sidebar layout with input and output definitions
        sidebarLayout(
          sidebarPanel(
            # Input: dropdown
            selectInput("organism", "Choose a dataset:",
                        choices = c("Kiwifruit", "pinus radiata", 
                                    "Muscadine grape", "European grape",
                                    "Soybean", "Maize", "Wheat", "Potato",
                                    "Cotton", "Canola", "Rice", "Rubus",
                                    "Vaccinium", "Sweet cherry", "Sour cherry",
                                    "Apple"),
                        selected = "Radiata pine"),
            # Horizontal line
            hr(),
            selectInput("assembly", "NCBI genome assembly:",
                        choices = c(
                          "GCA_000003025.6",
                          "GCA_000003025.7",
                          "GCA_000003025.8",
                          "GCA_000003025.9",
                          "GCA_000003025.10",
                          "GCA_000003025.11",
                          "GCA_000003025.12"
                        )),
            hr(),
            selectInput("linkage map", "Anchored linkage map:",
                        choices = c(
                          "GCA_000003025.6",
                          "GCA_000003025.7",
                          "GCA_000003025.8",
                          "GCA_000003025.9",
                          "GCA_000003025.10",
                          "GCA_000003025.11",
                          "GCA_000003025.12"
                        ))
          ),
          
          # Main panel for displaying outputs
          mainPanel(
            echarts4rOutput("contents")
          )
      ),
      fluidRow(
        # leaflet map output
        column(
          width = 12,
          leaflet::leafletOutput("map", height = "600px")
        )
      )
      )
    )
  )
}

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
