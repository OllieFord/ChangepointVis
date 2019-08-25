
#' Visual Interface for Unsupervised Changepoint Penalty Exploration
#'
#'@description { This function calculates the optimal positioning and (potentially) number of changepoints for a given univariate dataset using the user
#'specified range of penalty values.
#'It uses cpt.mean with the "PELT" method and "CROPS" penalty type from the changepoint package.
#'
#'
#'The function starts a shiny server and acompanying web interface that displays:
#' \enumerate{
#' \item The univariate datset (top left)
#' \item General statistics (top right)
#' \item Solution path (bottom left)
#' \item Weighted means histogram of the segments between changepoints.
#' }
#' The main form of interaction with the interface is through selecting each penalty value and then inspecting the resulting solution on the main plot (top left).
#'
#' }
#' @usage cpVisualise(data, penalty_range = c(1e-5,10))
#'
#' @name cpVisualise
#'
#' @param data A univariate dataset. This should be a vector containing the data within which you wish to find a changepoint.
#' @param penalty_range A range of penalty values. This will vary based on the datset and is used to compute changepoints for the data for each penalty value.
#'
#' @details {This function is used to find changes in mean for a given dataset using the PELT method.
#' The function visualises the data, along side an interactive solution path, allowing the usert to inspect how different penalty values impact the resulting changepoint locations.
#' Additional information is also presented to help the user interpret the data and specific penalty value. A table containing general statistics such as mean, variance etc and a weighted histogram, showing the distribution of segment means (weighted by length) for a particular penalty value.
#'
#'}
#' @import shiny
#' @import r2d3
#' @import htmlwidgets
#' @importFrom changepoint cpt.mean
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom stats var
#' @importFrom utils stack
#'
#'
#' @return Starts a shiny app in a new window.
#' @return Saves the currently selected solution as a .csv file, for use in cpLabel.
#'
#' @author Oliver Ford
#' @examples{
#' \dontrun{
#' # Basic example of creating a dummy dataset and running cpVisualise to explore a range of penalty values.
#'
#' data = c(rnorm(100,0,1),rnorm(100,5,1))
#' penalty_range = c(1e-5,10)
#' cpVisualise(data, penalty_range)
#' }
#' }
#' @export cpVisualise

cpVisualise <- function(data, penalty_range = c(1e-5,10)){

    shinyApp(
        ui <- fluidPage(

          tags$head(includeCSS(system.file('WWW', 'vis.css', package = 'CpVis'))),

          tags$div(class = "row",
                   tags$div(class = "col-lg-9",
                   tags$h3("CPVisualise")),
                   tags$div(class = "col-lg-3 center",
                   HTML("<button type='button' class='btn btn-primary send_data'>Save Changepoints</button>"))),
               tags$div(class = "row justify-content-md-left",
                        tags$div(class = "col-lg-9",
                                 tags$div(id = "main_output", d3Output("main_data"))
                                 #tags$div(id = "data_overview")
                                 ),
                        tags$div(class = "col-lg-3",
                                 tags$div(id = "data_overview",
                                          tags$div(class = "info"),
                                          tags$div(id = "mean_hist",
                                                   HTML("<p id=histControl>
                                                          <label>Amplitude</label>
                                                          <input type='number' min='0.1' max='50' step='0.1' value='0.6' id='amplitude'>
                                                          <label>  KDE</label>
                                                          <input type='number' min='1' max='100' step='1' value='2' id='KDEval'>
                                                          <label>  Resolution</label>
                                                          <input type='number' min='10' max='200' step='5' value='40' id='ticks'>
                                                          </p>

                                                        "))
                                          )
                                 )
                        )
        ),

        server <- function(input, output, session) {

          # run the change point method on the data - for differnet penalty values
          data.crops = changepoint::cpt.mean(data, method="PELT", penalty="CROPS", pen.value=penalty_range, class=FALSE)

          # list of all changepoints for each tested penalty value
          all_changepoints <- data.crops[2]
          clean_full_cpts <- unname(lapply(all_changepoints, function(x) x[!is.na(x)]))

          # dataframe that contains "beta_interval", "numberofchangepoints" and "penalised_cost"
          cpt_data <- t(data.frame(data.crops[1]))
          beta_interval = cpt_data[,1]
          numberofchangepoints = cpt_data[,2]
          penalised_cost = cpt_data[,3]
          solution_path_df <- data.frame(beta_interval, numberofchangepoints, penalised_cost)
          colnames(solution_path_df) <- c("beta_interval", "numberofchangepoints","penalised_cost")

          # general info about plot
          info <- list("Total Penalty Values" = nrow(solution_path_df),
                       "Penalty Range" = toString(penalty_range),
                       "Max Penalty Value" = max(solution_path_df[,1]),
                       "Min Penalty Value" = min(solution_path_df[,1]),
                       "Data Points" = length(data),
                       "Dataset Mean" = mean(data),
                       "Dataset Variance" = var(data),
                       "Max Data Value" = max(unlist(data)),
                       "Min Data Value" =  min(unlist(data)))
          info_df <- data.frame(stack(info))

          # convert the data to json
          json <- jsonlite::toJSON(c(data_set = list(data), cpts_full = clean_full_cpts, solution_path = list(solution_path_df), d_info = list(info_df)), pretty = TRUE)

          #output/send to client
          output$main_data <- renderD3({
                r2d3(data=json, script = system.file("JS/univariate_visualisation.js", package = "CpVis"), d3_version = 4, container = "div")
              })

          #save user selected label data to current working directory
          observeEvent(input$data_sent, {
              labels <- fromJSON(input$data_sent)
              if (dir.exists("saved_data")) {
                write.csv(labels,"saved_data/changePointLocations.csv", row.names = FALSE)
              } else {
                  dir.create("saved_data")
                  write.csv(labels,"saved_data/changePointLocations.csv", row.names = FALSE)
              }
          })


        }
    )

}
