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
                        choices = names(test_data),
                        selected = "actinidia"),
            # Horizontal line
            hr(),
            selectInput("assembly", "NCBI genome name:",
                        choices = test_data$actinidia$metadata$genome),
            selectInput("version", "Version:",
                        choices = c("v1", "v2", "v3")),
            hr(),
            plotOutput("phylo", height = "400px")
          ),
          
          # Main panel for displaying outputs
          mainPanel(
            echarts4rOutput("contents"),
            echarts4rOutput("donut")
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
