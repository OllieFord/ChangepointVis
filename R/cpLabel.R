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
  require(r2d3)
  require(jsonlite)
  require(htmlwidgets)
  require(shinyjs)
  require(survival)
  require(Segmentor3IsBack)
  require(changepoint)
  require(directlabels)
  require(data.table)
  require(penaltyLearning)


  shinyApp(
    ui <- fluidPage(
      tags$head(includeCSS(system.file('WWW', 'labelStyle.css', package = 'CpVis'))),

      tags$h3("CPLabel"),
      tags$div(class = "row justify-content-md-left",
               tags$div(class = "col-lg-10",
                        tags$div(id = "main_output", d3Output("main_data"))),

                        tags$div(class = "col-lg-2",
                                 tags$div(id = "control",
                                 HTML("<form id='label-type'>
                                        <label class='block'> <div class='small-box zero'></div> <input type='radio' id='normal' name='mode' checked></input> <span class='select'>   No label</span> </label>
                                        <label class='block'><div class='small-box two'></div> <input type='radio' id='breakpoint' name='mode'></input> <span class='select' >   Changepoint Region</span></label>
                                        </form>"),
                                 tags$div(id="segments", HTML("<div class='form-group'>
                                                                        <label for='exampleFormControlSelect1'>Number of Segments</label>
                                                                        <select class='form-control' id='segmentselect'>
                                                                          <option>2</option>
                                                                          <option>3</option>
                                                                          <option>4</option>
                                                                          <option>5</option>
                                                                          <option>6</option>
                                                                          <option>7</option>
                                                                          <option>8</option>
                                                                          <option>9</option>
                                                                          <option>10</option>
                                                                          <option>11</option>
                                                                          <option>12</option>
                                                                          <option>13</option>
                                                                          <option>14</option>
                                                                          <option>15</option>
                                                                        </select>
                                                                      </div>")),
                                 tags$div(id="run",
                                          HTML("<button type='button' class='btn btn-primary send_data'>Learn Penalties</button>")))

                                 )
                        )
    ),

    server <- function(input, output, session) {
      # convert the data to json
      json <- jsonlite::toJSON(c(data_set = list(data),  predictions = list("NULL")), pretty = TRUE)

      # print(json)
      #output/send to client


      output$main_data <- renderD3({


        if (is.null(input$data_sent)) {
          r2d3(data=json, script = system.file("JS/univariate_label.js", package = "CpVis"), d3_version = 4, container = "div")

        } else {

          labels <- fromJSON(input$data_sent)

          cpstore.labels <<- labels
          save(labels,file="labels.Rda")

          # segment the data into n models
          max.segments <- 2
          if (length(input$segmentnumber) > 0) {
            max.segments <- as.integer(input$segmentnumber)
          }
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
          (cpstore.segs <- cpstore.segs[!duplicated(cpstore.segs), ])


          (cpstore.changes <- cpstore.segs[1 < cpstore.segs$start,c("id", "subset", "n.segments", "rawStart")])
          cpstore.models <- data.table(
            id=1, subset=1,
            loss=cpstore.loss.vec,
            n.segments=as.numeric(1:max.segments))


          #convert to integers
          cpstore.changes$id <- as.integer(cpstore.changes$id)
          cpstore.changes$subset <- as.integer(cpstore.changes$subset)

          cpstore.error.list <- penaltyLearning::labelError(
            cpstore.models,
            cpstore.labels,
            cpstore.changes,
            change.var="rawStart",
            problem.vars=c("id", "subset"))

          (cpstore.selection <- penaltyLearning::modelSelection(
            cpstore.models, complexity="n.segments"))


          cpstore.error.join <- merge(cpstore.selection,cpstore.error.list$model.errors,by=c("id","subset", "n.segments", "loss"))

          cpstore.errors.tall <- data.table::melt(
            cpstore.error.join,
            measure.vars=c("n.segments", "errors"))

          (cpstore.target <- penaltyLearning::targetIntervals(
            cpstore.error.join,
            problem.vars=c("id", "subset")))


          minErrors <- which(cpstore.error.join$errors == min(cpstore.error.join$errors))

          if (length(minErrors) > 1) {
            segments <- c()
            for  (error in minErrors) {
              predictedSegments <- cpstore.error.join$n.segments[error]
              segments <- c(segments, predictedSegments)
            }
            predictedSegments <- min(segments)
          } else {
            predictedSegments <- cpstore.error.join$n.segments[minErrors]
          }

          targetIndex <- which(grepl(cpstore.target$min.log.lambda, cpstore.selection$min.log.lambda))
          predictedSegments <- cpstore.selection[targetIndex,]$n.segments
          predictedChangeLocations <- cpstore.changes[cpstore.changes$n.segments == predictedSegments,]$rawStart


          #predictedChangeLocations <- cpstore.changes[cpstore.changes$n.segments == predictedSegments,]$rawStart

          predictedChange <- jsonlite::toJSON(c(data_set = list(data), predictions = list(predictedChangeLocations)), pretty = TRUE)
          r2d3(data=predictedChange, script = system.file("JS/univariate_label.js", package = "CpVis"), d3_version = 4, container = "div")

        }

      })



    }
  )

}
