
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
cpVis <- function(data, penalty_range = c(1e-5,10)){

  require(shiny)
  require(changepoint)

    shinyApp(
        ui <- fluidPage(
            titlePanel("Base Change Point Visualisation"),
            sidebarLayout(
              sidebarPanel(position = "left",
                           textOutput("no_cp"),
                           textOutput("pen_val")),

            mainPanel(position = "right",
                      plotOutput(outputId = "scatter"),
                      plotOutput(outputId = "solutionPath",
                                 click = hoverOpts(id = "plot_click",
                                                   delay = 40,
                                                   delayType = "debounce")
                                 )
                      )
            )
            ),

        server <- function(input, output, session) {

          # run the change point method on the data - for differnet penalty values
          data.crops = cpt.mean(data, method="PELT", penalty="CROPS", pen.value=penalty_range)

          # Code taken and adapted from change point package - finds all possible changepoints
          pos_ncpts = apply(cpts.full(data.crops), 1, function(data.crops) sum(data.crops > 0, na.rm = TRUE))

          #reactive values for mouse position and possible change points
          values <- reactiveValues(loc = length(data.crops@pen.value.full) / 2)
          pos_value <- reactiveValues(loc = length(data.crops@pen.value.full) / 2)

          # reactively update values based on chnaging mouse input
          observeEvent(input$plot_click$x, {
            values$loc <- round(input$plot_click$x, 1)

            pos_value$loc <- which(abs(pos_ncpts - values$loc)==min(abs(pos_ncpts - values$loc)))
            if (length(pos_value$loc) > 1) {
              pos_value$loc = pos_value$loc[1]
            }
          })

            #plot data + change points
            output$scatter <- renderPlot({
              plot(data.crops, ncpts=pos_ncpts[pos_value$loc], cpt.width=3, cpt.col='blue')
            })

            # plot solution path + currently selected change point number
            output$solutionPath <- renderPlot({
              plot(data.crops, diagnostic=TRUE)
              abline(v = pos_ncpts[pos_value$loc], col="red", lwd=3, lty=2)
            })


            #display number of change points
            output$no_cp <- renderText({
              paste("Change Points:", pos_ncpts[pos_value$loc], sep = "\n")
            })

            #display penalty value
            output$pen_val <- renderText({
              paste("Penalty Value:", data.crops@pen.value.full[pos_value$loc], sep = "\n")
            })

        }
    )
}
