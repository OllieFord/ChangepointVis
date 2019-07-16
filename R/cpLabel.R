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
#'



cpLabel <- function(data){
  require(shiny)
  require(changepoint)
  require(r2d3)
  require(jsonlite)
  require(htmlwidgets)
  require(shinyjs)
  require(penaltyLearning)
  require(data.table)
  library(penaltyLearning)
  library(data.table)
  library(tidyverse)

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

          cpstore.labels <<- labels
          save(labels,file="labels.Rda")

          # segment the data into n models
          max.segments <- 7
          (fit <- Segmentor3IsBack::Segmentor(data, model=2, Kmax=max.segments))

          data_store <- data.frame( id = rep(1, length(data)),
                                     subset = rep(1, length(data)),
                                     position= c (1:length(data)),
                                    data = data)

          cpstore.segs.list <- list()
          cpstore.loss.vec <- rep(NA, max.segments)

          for (n.segments in 1:max.segments) {

            end <- fit@breaks[n.segments, 1:n.segments]
            data.before.change <- end[-n.segments]
            data.after.change <- data.before.change+1
            pos.before.change <- as.integer((data_store$position[data.before.change]+data_store$position[data.after.change])/2)
            start <- c(1, data.after.change)
            rawStart <- c(data_store$position[1], pos.before.change)
            rawEnd <- c(pos.before.change, max(data_store$position))
            seg.mean.vec <- fit@parameters[n.segments, 1:n.segments]
            cpstore.segs.list[[n.segments]] <- data.table(
              id=paste(data_store$id),
              subset=paste(data_store$subset),
              n.segments, # model complexity.
              start,
              end,
              rawStart,
              rawEnd,
              mean=seg.mean.vec)
            data.mean.vec <- rep(seg.mean.vec, end-start+1)
            stopifnot(length(data.mean.vec)==nrow(data_store))
            cpstore.loss.vec[n.segments] <- sum((data_store$data-data.mean.vec)^2)
          }

          (cpstore.segs <- do.call(rbind, cpstore.segs.list))
          cpstore.segs <- cpstore.segs[!duplicated(cpstore.segs), ]

          # print(start)
          # print(n.segments)
          # print(rawStart)

          print(cpstore.segs)
          print(cpstore.segs[start > 1, ])
          print(cpstore.segs[1 < start, c("id", "subset", "n.segments", "rawStart")])
          print(cpstore.segs[start > 1, ])
          blob <- cpstore.segs[1 < start, ]
          print(blob)


          #(cpstore.changes <- cpstore.segs[1 < start, c("id", "subset", "n.segments", "rawStart")])

          (cpstore.changes <- cpstore.segs[1 < start, data.table(
            subset = 1,id=1, n.segments)])


          cpstore.models <- data.table(
            id=1, subset=1,
            loss=cpstore.loss.vec,
            n.segments=as.numeric(1:max.segments))


          cpstore.changes$id <- as.integer(cpstore.changes$id)

          cpstore.changes$subset <- as.integer(cpstore.changes$subset)


          print(cpstore.changes)
          print(cpstore.labels)
          print(cpstore.models)

          cpstore.error.list <- penaltyLearning::labelError(
            cpstore.models,
            cpstore.labels,
            cpstore.changes,
            change.var="rawStart",
            problem.vars=c("id", "subset"))


          (cpstore.selection <- penaltyLearning::modelSelection(
            cpstore.models, complexity="n.segments"))

          cpstore.error.join <- cpstore.error.list$model.errors[J(cpstore.selection), on=list(
            id, subset, n.segments, loss)]

          cpstore.errors.tall <- data.table::melt(
            cpstore.error.join,
            measure.vars=c("n.segments", "errors"))

          (cpstore.target <- penaltyLearning::targetIntervals(
            cpstore.error.join,
            problem.vars=c("id", "subset")))



          print(cpstore.target)
        }

      })



    }
  )

}
