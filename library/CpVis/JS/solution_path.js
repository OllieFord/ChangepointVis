// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)
//
// r2d3: https://rstudio.github.io/r2d3
//

//console.log(d3.keys(data));

var data_arr = [];
data_arr.push(data);

var no_cpts = [];
var pen_val = [];
for (i = 0; i < data.length; i++) {
  no_cpts.push(data[i]['no_cpts'])
  pen_val.push(data[i]['pen_val']);
}

console.log(no_cpts);
console.log(pen_val);



var parentDiv = document.getElementById("solution_path");
var width = parentDiv.clientWidth;
var height = parentDiv.clientHeight;

var margin = {top: 50, right: 0, bottom: 50, left: 50};

var xpadding = 50;
var ypadding = 30;

var xScale = d3.scaleLinear()
    .domain([d3.min(no_cpts), d3.max(no_cpts)]) // input
    .range([xpadding, width - xpadding]);

var yScale = d3.scaleLinear()
							.domain([d3.min(pen_val), d3.max(pen_val)])
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
			   .data(data)
			   .enter()
			   .append("circle")
			   .attr("cx", function(d) {
			   		return xScale(Number(d.no_cpts));
			   })
			   .attr("cy", function(d) {
			   		return yScale(Number(d.pen_val));
			   })
			   .attr("r", 2);

r2d3.svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);


r2d3.svg.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + ypadding + ", 0)")
    .call(yAxis);

