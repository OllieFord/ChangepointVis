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
  require(magrittr)
  require(data.table)
  require(tidyverse)

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
                                        <label class='block'> <div class='small-box zero'></div> <input type='radio' id='normal' name='mode' checked></input> <span class='select'>   No label</span> </label>
                                        <label class='block'> <div class='small-box one'></div> <input type='radio' id='multiple_breakpoints' name='mode'></input> <span class='select' >    Changepoint Region</span></label>
                                        <label class='block'><div class='small-box two'></div> <input type='radio' id='breakpoint' name='mode'></input> <span class='select' >   Single Changepoint</span></label>
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

          # segment the data into n models
          max.segments <- 7
          (fit <- Segmentor3IsBack::Segmentor(data, model=2, Kmax=max.segments))

          data_store <- data.frame( id = rep(1, length(data)),
                                     subset = rep(1, length(data)),
                                     position= c (1:length(data)),
                                    data = data)

          cpstore.segs.list <- list()
          cpstore.loss.vec <- rep(NA, max.segments)
          for(n.segments in 1:max.segments){
            end <- fit@breaks[n.segments, 1:n.segments]
            data.before.change <- end[-n.segments]
            data.after.change <- data.before.change+1
            pos.before.change <- as.integer(
              (data_store$position[data.before.change]+
                 data_store$position[data.after.change])/2)
            start <- c(1, data.after.change)
            rawStart <- c(data_store$position[1], pos.before.change)
            rawEnd <- c(pos.before.change, max(data_store$position))
            seg.mean.vec <- fit@parameters[n.segments, 1:n.segments]
            cpstore.segs.list[[n.segments]] <- data.table(
              id=paste(data_store$id),
              subset=paste(data_store$subset),
              n.segments, # model complexity.
              start, # in data points.
              end,
              rawStart, # in bases on chromosome.
              rawEnd,
              mean=seg.mean.vec)
            data.mean.vec <- rep(seg.mean.vec, end-start+1)
            stopifnot(length(data.mean.vec)==nrow(data_store))
            cpstore.loss.vec[n.segments] <- sum((data_store$data-data.mean.vec)^2)
          }

          (cpstore.segs <- do.call(rbind, cpstore.segs.list))
          cpstore.segs <- cpstore.segs %>% distinct()

          (cpstore.changes <- cpstore.segs[1 < start, data.table(
            id, subset, n.segments,
            changepoint=rawStart)])
          return(labels)
        }

      })

    }
  )

}
