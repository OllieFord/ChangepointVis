// !preview r2d3 data=c(5, 20, 480, 90, 250, 50, 0, 33, 330, 95), d3_version = 4
//
// r2d3: https://rstudio.github.io/r2d3
//

var data = r2d3.data;

//console.log(data);

var no_cpts = data;
var pen_val = [];
var data_set = data.data_set;

console.log(data_set)

var parentDiv = document.getElementById("main_output");
var width = parentDiv.clientWidth;
var height = parentDiv.clientHeight;
var margin = {top: 50, right: 0, bottom: 50, left: 50};

var xpadding = 50;
var ypadding = 30;

var xScale = d3.scaleLinear()
    .domain([d3.min(data_set), data_set.length-1]) // input
    .range([xpadding, width - xpadding]);

var yScale = d3.scaleLinear()
							.domain([d3.min(data_set), d3.max(data_set)])
							.range([height - ypadding, ypadding]);

var xAxis = d3.axisBottom()
							  .scale(xScale);

var yAxis = d3.axisLeft()
							  .scale(yScale)

r2d3.svg
.attr("width", width + margin.left + margin.right)
.attr("height", height + margin.top + margin.bottom)
.append("g")
.attr("transform", "translate(" + margin.left + "," + margin.top + ")");


r2d3.svg.selectAll("circle")
			   .data(data_set)
			   .enter()
			   .append("circle")
			   .attr("cx", function(d, i) {
			   		return xScale(i);
			   })
			   .attr("cy", function(d) {
			   		return yScale(d);
			   })
			   .attr("r", 2);

svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);


svg.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + ypadding + ", 0)")
    .call(yAxis);

