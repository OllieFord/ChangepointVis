#' Visual Interface for Labeling and learning a penalty function
#'
#'
#'@description { This Function implements a simple changepoint labeling tool as well as the penalty learning algorithm to learn a penalty function that can be used to accurately predict changepoints in labeled data.
#'
#'The function starts a shiny server and acompanying web interface that displays:
#' \enumerate{
#' \item The univariate datset (top left)
#' \item Control Pannel (top right)
#' }
#' The main form of interaction with the interface is through selecting a label type (top right) and then selecting regions of the data which you would like to assign said label type.
#' Additionaly, by clicking "learn Penalties" a penalty function is learned from the labeled data and the resulting changepoint(s) are displayed.
#'
#' }
#'
#' @usage cpLabel(data, unsupervised_changepoints = FALSE)
#'
#' @name cpLabel
#'
#' @param data A univariate dataset.
#' @param unsupervised_changepoints a boolean value, if set to TRUE, the function will try to load changepoints that were created by cpVisulaise and use these to label the data on startup.
#'
#' @details {This function is used to both label a dataset and to learn a penalty function from the labeled data. Furthermore, this labeled data can be exported for use in other applications.
#' NoLabel Used to create regions where no changepoints should be.
#' ChangePointRegion Used to create regions where changepoints should be.
#' NumberofSegments used to determine how many models should be evaluated for the given labeled data. Roughly equates to the number of changepoints you belive should be in the data.
#' LearnPenalties run the penalty learning algorithm given the labeled data. Returns predicted changepoints.
#' SaveLabels saves the labels as a .csv file.
#'
#' In addition to the base functionality, this function also allows the data to be pre-labeled using changepoints found using the unsupervised methods in cpVisualise. This can be done by first selecting and saving a solution in cpVisualise (by clicking the "save changepoints" button) and then running cpLabel with \strong{unsupervised_changepoints} set to TRUE. }
#'
#' @import shiny
#' @import r2d3
#' @import htmlwidgets
#' @import survival
#' @import directlabels
#' @import data.table
#' @import penaltyLearning
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom Segmentor3IsBack Segmentor
#' @importFrom utils globalVariables
#' @importFrom utils read.csv write.csv
#'
#'
#' @return starts a shiny app in a new window
#'
#'
#' @examples{
#' \dontrun{
#' # Basic example of creating a dummy dataset and running cpLabel.
#' data = c(rnorm(100,0,1),rnorm(100,5,1))
#' cpLabel(data)
#' }
#' }
#'
#'
#' @export cpLabel

cpLabel <- function(data, unsupervised_changepoints = FALSE){

  if (unsupervised_changepoints) {
    print("Loading unsupervised Changepoints")
    unsupervisedLabels <- tryCatch(read.csv(file="saved_data/changePointLocations.csv", header=TRUE, sep=","), error=function(e) 1)
    unsupervisedLabels <- tryCatch(as.list(unsupervisedLabels['changepoint']), error=function(e) 1)
  }

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
                                                                        <select class='form-control' id='segmentselect'></select>
                                                                      </div>")),
                                 includeScript(system.file('WWW', 'dropdownRange.js', package = 'CpVis')),
                                 tags$div(id="run",
                                          HTML("<button type='button' class='btn btn-primary send_data'>Learn Penalties</button>")),
                                 tags$div(id="save",
                                          HTML("<button type='button' class='btn btn-primary save_data'>Save Labels</button>")))

                                 )
                        )
    ),

    server <- function(input, output, session) {

      if (!is.na(unsupervised_changepoints)) {
        print("Converting data and unsupervised labels to json")
        json <- jsonlite::toJSON(c(data_set = list(data),  predictions = list("NULL"), unsup_labels = list(unsupervisedLabels)), pretty = TRUE)
      } else {
        print("Converting data to json")
        json <- jsonlite::toJSON(c(data_set = list(data),  predictions = list("NULL")), pretty = TRUE)
        }
      cpstore.labels <- "data"

      #output/send to client
      output$main_data <- renderD3({

        if ((input$data_sent)) {
          r2d3(data=json, script = system.file("JS/univariate_label.js", package = "CpVis"), d3_version = 4, container = "div")

        } else {
          labels <- fromJSON(input$data_sent)
          cpstore.labels <<- labels

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

          predictedChange <- jsonlite::toJSON(c(data_set = list(data), predictions = list(predictedChangeLocations)), pretty = TRUE)
          r2d3(data=predictedChange, script = system.file("JS/univariate_label.js", package = "CpVis"), d3_version = 4, container = "div")

        }

      })

      #for future use - to save labels to csv file, will probably make a button in interface to save results.
      # session$onSessionEnded(function() {
      #   print(cpstore.labels)
      #
      # })

      #save user selected label data to current working directory
      observeEvent(input$data_save, {
        labels <- fromJSON(input$data_save)
        if (dir.exists("saved_data")) {
          write.csv(labels,"saved_data/changePointLabels.csv", row.names = FALSE)
        } else {
          dir.create("saved_data")
          write.csv(labels,"saved_data/changePointLabels.csv", row.names = FALSE)
        }
      })



    }
  )

}
