
#' Visual Interface for Changepoint Penalty Exploration (D3 version)
#'
#' This function takes a univariate dataset as input, as well as a range of penalty values.
#' It uses cpt.mean with the "PELT" method and "CROPS" penalty type from the changepoint package.
#' @name cpVis_d3
#'
#' @param data A univariate dataset
#' @param penalty_range A range of penalty values
#'
#' @return starts a shiny app in a new window
#' @export
#'
#' @examples
#' data = c(rnorm(100,0,1),rnorm(100,5,1))
#' cpVis_d3(data, penalty_range = c(1e-5,10))
#'
library(r2d3)
library(jsonlite)
library(htmlwidgets)
library(shiny)
library(shinyjs)

cpVis_d3 <- function(data, penalty_range = c(1e-5,10)){

  require(shiny)
  require(changepoint)
  require(r2d3)
  require(jsonlite)
  require(htmlwidgets)
  require(shinyjs)

    shinyApp(
        ui <- fluidPage(
          inlineCSS(".axis {font: 10px sans-serif;}
                    h2 {text-align: center;}
                    #solution_path {height: 400px; width: 70vw; margin: 30px;}"),

          tags$head(
          #tags$link(rel = "stylesheet", type = "text/css", href = "main.css")
        ),

            titlePanel("Change Point Visualisation"),
               tags$div(class = "row justify-content-md-left",
                        tags$div(class = "col-lg-9",
                                 tags$div(id = "main_output", d3Output("main_data"))
                                 #tags$div(id = "data_overview")
                                 ),
                        tags$div(class = "col-lg-3",
                                 tags$div(id = "data_overview")
                                 )
                        )
        ),

        server <- function(input, output, session) {

          # run the change point method on the data - for differnet penalty values
          data.crops = cpt.mean(data, method="PELT", penalty="CROPS", pen.value=penalty_range)

          dataset_mean <- mean(data)
          total_penalty_values <-

          full_cpts <- split(data.crops@cpts.full, 1:nrow(data.crops@cpts.full))

          #remove NA values and names
          clean_full_cpts = list(unname(lapply(full_cpts, function(x) x[!is.na(x)])))

          # list containing number of changepoints for every penalty value
          number_changepoints = list(apply(data.crops@cpts.full, 1, function(x) sum(x > 0, na.rm = TRUE)))

          #list containing all penalty values
          penalty_values = list(data.crops@pen.value.full)


          info <- list("Total Penalty Values" = lengths(penalty_values),
                       "Penalty Range" = toString(penalty_range),
                       "Max Penalty Value" = max(unlist(data.crops@pen.value.full)),
                       "Min Penalty Value" = min(unlist(data.crops@pen.value.full)),
                       "Data Points" = length(data),
                       "Dataset Mean" = mean(data),
                       "Dataset Variance" = var(data),
                       "Max Data Value" = max(unlist(data)),
                       "Min Data Value" =  min(unlist(data)))
          info_df <- data.frame(stack(info))

          # dataframe containing changepoints and penalty values as columns
          solution_path_df <- data.frame(number_changepoints, penalty_values)
          colnames(solution_path_df) <- c("changepoints", "penalty_values")

          # convert the data to json
          json <- jsonlite::toJSON(c(data_set = list(data.crops@data.set), cpts_full = clean_full_cpts, solution_path = list(solution_path_df), d_info = list(info_df)), pretty = TRUE)
          print(json)
          #output/send to client
          output$main_data <- renderD3({
                r2d3(data=json, script = system.file("JS/univariate_visualisation.js", package = "CpVis"), d3_version = 4, container = "div")
              })

        }
    )

}
