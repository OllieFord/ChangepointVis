// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)
//
// r2d3: https://rstudio.github.io/r2d3
//

var data = r2d3.data;

var parentDiv = document.getElementById("main_output");

for (i = 0; i< data.predictions.length; i++){
	   main_plot.append("line")
	          .attr("class", "pc-means")
	          .transition()
	          .duration(300)
	          .attr("x1", mainXScale(filtered_change_location[i]))
	          .attr("y1", mainYScale(means[i]))
	          .attr("x2", mainXScale(filtered_change_location[i+1]))
	          .attr("y2", mainYScale(means[i]))
	          .style("fill", "none")
	          .style("stroke", accent_colour)
	          .style("stroke-width", 2)
      			 }

