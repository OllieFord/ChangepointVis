// !preview r2d3 data=c(-0.138, -0.6253, 0.5587)
//
// r2d3: https://rstudio.github.io/r2d3
//
var data = r2d3.data;
var labels = new Array(data.data_set.length).fill('normal');

// recieve data - changepoint indexes
// find smallest distance between numbers
// convert indexes to ranges (add padding either side of label, max padding = min distance between changepoints -1)

// add padding to breakpoint regions

console.log(labels);

const accentColour = "#4363d8"; //blue

const blue = "#2c7bb6";
const red = "#d7191c";

var parentDiv = document.getElementById("main_output");

const margin = {top: 20, right: 20, bottom: 110, left:40};
var margin2 = {top: 390, right: 20, bottom: 30, left: 40};
var width = parentDiv.clientWidth - margin.left - margin.right;
var height = parentDiv.clientHeight - margin.top - margin.bottom;

var widthPadding = 20;
var heightPadding = 20;

const x = d3.scaleLinear().range([(0 + widthPadding), (width - widthPadding)]).nice(),
      y = d3.scaleLinear().range([height - heightPadding, (0 + heightPadding)]).nice(),
      labelScale = d3.scaleLinear().domain([widthPadding, width - widthPadding]).range([0, data.data_set.length]),
      z = d3.scaleLinear().domain([0, data.data_set.length]).range([widthPadding, (width - widthPadding)]);

//console.log(x);

const xAxis = d3.axisBottom(x),
    yAxis = d3.axisLeft(y);


var container = div.style("background", "none")
              .style("height", "90%");

var mainPlot = container
  .append("svg")
  .attr("class", "main")
  .style("width", "100%")
  .style("height", "100%")
  .style("border-radius", "4px")
  .style("box-shadow", "0px 18px 40px -12px rgba(196,196,196,0.35)")
  .style("background", "#ffffff")
  .style("margin", "10px");

var dataVisualisation = mainPlot.append("g")
    .attr("class", "dataVisualisation")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

x.domain(d3.extent(data.data_set, function(d, i) { return i; })).nice();
y.domain([d3.min(data.data_set), d3.max(data.data_set)]).nice();

var mainDataLine = d3.line()
            .x(function(d, i) { return x(i); })
            .y(function(d) { return y(d); });

dataVisualisation.append("path")
          .datum(data.data_set)
          .attr("class", "main-line")
          .attr("fill", "none")
          .attr("stroke", accentColour)
          .attr("d", mainDataLine);

dataVisualisation.call( d3.brushX()
        .extent( [ [widthPadding, heightPadding], [width-widthPadding, height - heightPadding] ] )
        .on("end", updateChart)
      );

if (data.unsup_labels.changepoint) {
  new_labels = addLabelPadding();
  useUnsupervisedLabels(new_labels);
  showAnnotation();
}

function showAnnotation() {
    var annotations = [];
    var positions = [];
    var min = [];
    var max = [];
    var breakpointRanges = [];

    breakpointRanges = breakpointLabelRanges();

    breakpointNestedLabels = convertNestedPairs(breakpointRanges);

    convertedLabelData = convertAnnotationData(labels, annotations, min, max, positions);

    dataVisualisation.selectAll("bar")
      .data(breakpointNestedLabels)
      .enter()
      .append("rect")
      .attr("class", "class_rect")
      .attr("x", function(d) { return x(d[0]) })
      .attr("y", heightPadding)
      .attr("height", (height - (heightPadding * 2)))
      .attr("width", function(d) { return z(Math.abs(d[1] - d[0]))}) // magic 2 until i figure out the issue - will not work for other data.
      .attr("fill", red)
      .style("opacity", "0.2")
      .style("stroke", "none");
}


function updateChart() {
      var annotations = [];
      var positions = [];
      var min = [];
      var max = [];
      var breakpointRanges = [];
      var formValue;

    labelSelection();
    extent = d3.event.selection;
    var range = d3.extent(extent, function(d) { return Math.round(labelScale(d)) });
    // update label storage
    for (let i = range[0] ; i< range[1]; i++){
        labels[i] = formValue;
    }

    breakpointRanges = breakpointLabelRanges();
    breakpointNestedLabels = convertNestedPairs(breakpointRanges);

    dataVisualisation.selectAll(".class_rect").remove();
    dataVisualisation.selectAll(".overlay").remove();
    dataVisualisation.selectAll(".selection").remove();
    dataVisualisation.selectAll(".handle").remove();

    convertedLabelData = convertAnnotationData(labels, annotations, min, max, positions);

    dataVisualisation.selectAll("bar")
      .data(breakpointNestedLabels)
      .enter()
      .append("rect")
      .attr("class", "class_rect")
      .attr("x", function(d) { return x(d[0]) })
      .attr("y", heightPadding)
      .attr("height", (height - (heightPadding * 2)))
      .attr("width", function(d) { return z(Math.abs(d[1] - d[0]))}) // magic 2 until i figure out the issue - will not work for other data.
      .attr("fill", red)
      .style("opacity", "0.2")
      .style("stroke", "none");

      dataVisualisation.call( d3.brushX()
        .extent( [ [widthPadding, heightPadding], [width-widthPadding, height - heightPadding] ] )
        .on("end", updateChart));

      mainPlot.selectAll(".selection").style("display", "none"); // used to remove selection after interaction.


      function labelSelection() {
        var labelForm = document.getElementById("label-type");

      	for(let i=0; i<labelForm.length; i++){
      	    if(labelForm[i].checked){
              formValue = labelForm[i].id;
      	    }
      	   }
      }
}

let sendLabelData2Server = d3.select(".send_data")
              .on("click", function(){
                console.log(JSON.stringify(convertedLabelData));
                  Shiny.setInputValue(
                    "data_sent",
                    JSON.stringify(convertedLabelData),
                    {priority: "event"}
                    )});

let sendSegmentNumber2Server = d3.select("#segmentselect")
              .on("change", function(){
                  Shiny.setInputValue(
                    "segmentnumber",
                    d3.select(this).property("value"),
                    {priority: "event"}
                    )});

function convertNestedPairs(breakpointRanges){
      let breakLabels = [];
      for (let i = 0 ; i< breakpointRanges.length; i += 2){
        breakLabels.push([breakpointRanges[i], breakpointRanges[(i+1)]]);
      }
      return breakLabels;
    }

function breakpointLabelRanges() {
        var breakpointRanges =[]
        var flipFlop = true;
        for (let i = 0 ; i< labels.length; i++){
            if (labels[i] === "breakpoint" && flipFlop === true) {
              breakpointRanges.push(i);
              flipFlop = false;
            }
            if (labels[i] != labels[(i+1)] && flipFlop === false) {
              breakpointRanges.push((i+1));
              flipFlop = true;
            }
        }
        return breakpointRanges
    }

function convertAnnotationData(labels, annotations, min, max, positions) {
      for (let i = 0; i < labels.length; i++) {
        if(labels[i] != labels[i+1]) {
          annotations.push(labels[i]);
          positions.push(i);
          }
      }
      for (let i = 0; i < positions.length; i++) {
        if (i === 0){
          min[i] = 0;
          max[i] = positions[i];
        }
        else {
          min[i] = (positions[i-1] + 1);
          max[i] = positions[i];
        }
      }

      let tmp_data = [];
      for (let i = 0; i < annotations.length; i++) {
        let tmp = {id:1, subset:1, min:min[i], max:max[i], annotation:annotations[i] };
        tmp_data.push(tmp);
      }
      return tmp_data;
}

function addLabelPadding(){
  var new_labels = [];
  for (let i = 0; i < data.unsup_labels.changepoint.length; i++) {
    new_labels.push((data.unsup_labels.changepoint[i] -1));
    new_labels.push((data.unsup_labels.changepoint[i]));
    new_labels.push((data.unsup_labels.changepoint[i] +1));
  }
  return new_labels;
}

function useUnsupervisedLabels(new_labels) {
  for (let i = 0; i < new_labels.length; i++) {
  labels[new_labels[i]] = "breakpoint";
  }
}

r2d3.onRender(function(data) {

  if (data.predictions[0] === "NULL") {

  } else {
    dataVisualisation.selectAll(".predictedChangepoints").remove();

    for (let i = 0; i < data.predictions.length; i++) {

      dataVisualisation.append('line')
                      .transition()
                      .ease(d3.easeLinear)
                      .attr("class", "predictedChangepoints")
                      .attr("x1", x(data.predictions[i]))
                      .attr("x2", x(data.predictions[i]))
                      .attr("y1", heightPadding)
                      .attr("y2", (height - (10 * 2)))
                      .style("stroke", "#000000")
                      .style("stroke-width", 3)

    }
  }

});

dataVisualisation.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

dataVisualisation.append("text")
      .attr("transform", "translate(" + (width/2) + " ," + (height + margin.top + 5) + ")")
      .style("text-anchor", "middle")
      .attr("font-size", "2rem")
      .text("Time")
      .style("color", "#000000");

dataVisualisation.append("g")
      .attr("class", "axis axis--y")
      .call(yAxis);

dataVisualisation.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 0- margin.left/18)
      .attr("x",0 - (height / 2))
      .attr("dy", "1em")
      .style("text-anchor", "middle")
      .attr("font-size", "2rem")
      .text("Value")
      .style("color", "#000000");
