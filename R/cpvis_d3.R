
#' Visual Interface for Changepoint Penalty Exploration
#'
#' This function takes a univariate dataset as input, as well as a range of penalty values.
#' It uses cpt.mean with the "PELT" method and "CROPS" penalty type from the changepoint package.
#'
#'
#' @param data A univariate dataset
#' @param penalty_range A range of penalty values
#'
#' @return starts a shiny app in a new window
#' @export
#'
#' @examples
#' data = c(rnorm(100,0,1),rnorm(100,5,1))
#' cpVis(data, penalty_range = c(1e-5,10))
#'
library(r2d3)
library(jsonlite)
library(htmlwidgets)


  data = c(rnorm(100,0,1),rnorm(100,5,1))

  require(shiny)
  require(changepoint)
  require(r2d3)

    shinyApp(
        ui <- fluidPage(

          tags$head(
          tags$link(rel = "stylesheet", type = "text/css", href = "main.css")
        ),

            titlePanel("Change Point Visualisation"),

        tags$div(id = "main_output", d3Output("main_data")),
        tags$div(id = "data_overview")

        ),

        server <- function(input, output, session) {

          # run the change point method on the data - for differnet penalty values
          data.crops = cpt.mean(data, method="PELT", penalty="CROPS", pen.value=c(1e-5,10))

          full_cpts <- split(data.crops@cpts.full, 1:nrow(data.crops@cpts.full))

          #remove NA values and names
          clean_full_cpts = list(unname(lapply(full_cpts, function(x) x[!is.na(x)])))

          # list containing number of changepoints for every penalty value
          number_changepoints = list(apply(data.crops@cpts.full, 1, function(x) sum(x > 0, na.rm = TRUE)))

          #list containing all penalty values
          penalty_values = list(data.crops@pen.value.full)

          # dataframe containing changepoints and penalty values as columns
          solution_path_df <- data.frame(number_changepoints, penalty_values)
          colnames(solution_path_df) <- c("changepoints", "penalty_values")

          # convert the data to json
          json <- jsonlite::toJSON(c(data_set = list(data.crops@data.set), cpts_full = clean_full_cpts, solution_path = list(solution_path_df)), pretty = TRUE)

          #output/send to client
          output$main_data <- renderD3({
                r2d3(data=json, script = "JS/univariate_visualisation.js", d3_version = 4, container = "div")
              })

        }
    )

    shinyApp(ui = ui, server = server)
