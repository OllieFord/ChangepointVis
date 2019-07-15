#' Visual Interface for Changepoint Penalty Exploration (D3 version)
#'
#' This function takes a univariate dataset as input. Provides simple labeling and exporting functionality for univariate time seriese data.
#'
#' @name cpvisLabel
#'
#' @param data A univariate dataset
#'
#'
#' @return starts a shiny app in a new window
#' @export
#'
#' @examples
#' data = c(rnorm(100,0,1),rnorm(100,5,1))
#' cpLabel(data)
#'

cpLabel <- function(data){
  require(shiny)
  require(changepoint)
  require(r2d3)
  require(jsonlite)
  require(htmlwidgets)
  require(shinyjs)

  shinyApp(
    ui <- fluidPage(
      tags$head(includeCSS(system.file('WWW', 'main.css', package = 'CpVis'))),

      titlePanel("Change Point Labeling"),
      tableOutput("selected"),
      tags$div(class = "row justify-content-md-left",
               tags$div(class = "col-lg-10",
                        tags$div(id = "main_output", d3Output("main_data"))),

                        tags$div(class = "col-lg-2",
                                 tags$div(id = "control",
                                 HTML("<form id='label-type'>
                                        <label class='block'> <div class='small-box zero'></div> <input type='radio' id='0' name='mode' checked></input> <span class='select'>   No label</span> </label>
                                        <label class='block'> <div class='small-box one'></div> <input type='radio' id='1' name='mode'></input> <span class='select' >    Changepoint Region</span></label>
                                        <label class='block'><div class='small-box two'></div> <input type='radio' id='2' name='mode'></input> <span class='select' >   Single Changepoint</span></label>
                                        </form>")),
                                 tags$div(id="run",
                                          HTML("<button type='button' class='btn btn-primary send_data'>Learn Penalties</button>"))

                                 )
                        )
    ),

    server <- function(input, output, session) {
      # convert the data to json
      json <- jsonlite::toJSON(c(data_set = list(data)), pretty = TRUE)

      #print(json)
      #output/send to client
      output$main_data <- renderD3({
        r2d3(data=json, script = system.file("JS/univariate_label.js", package = "CpVis"), d3_version = 4, container = "div")
      })



      output$selected <- renderTable({

        if (is.null(input$data_sent)) {
        } else {
          labels <- fromJSON(input$data_sent)
          return(labels)
        }

      })

    }
  )

}
