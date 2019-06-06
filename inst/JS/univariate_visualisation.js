// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)
//
// r2d3: https://rstudio.github.io/r2d3
//


var data = r2d3.data;

var changepoint_lengths = [];
for (i = 0; i < data.cpts_full.length; i++) {
  changepoint_lengths.push(data.cpts_full[i].length)
}

// compute count of all changepoints

var counts = {};
for (var i = 0; i < data.cpts_full.length; i++) {
  for(var j=0; j< data.cpts_full[i].length; j++){
    var num = data.cpts_full[i][j];
    counts[num] = counts[num] ? counts[num] + 1 : 1;
  }
}

var counts_values = d3.values(counts);


var parentDiv = document.getElementById("main_output");
var width = parentDiv.clientWidth;
var height = parentDiv.clientHeight;
var margin = {top: 50, right: 0, bottom: 50, left: 50};

var xpadding = 80;
var ypadding = 70;

var mainXScale = d3.scaleLinear()
    .domain([d3.min(data.data_set), data.data_set.length-1]) // input
    .range([xpadding, width - xpadding]);

var mainYScale = d3.scaleLinear()
							.domain([d3.min(data.data_set), d3.max(data.data_set)])
							.range([height - ypadding, ypadding]);

var histYScale = d3.scaleLinear()
							.domain([d3.min(counts_values), data.cpts_full.length ])
							.range([height,  height - ypadding]);

var sp_cp_min = d3.min(data.solution_path, function(d) { return +d.changepoints;});
var sp_cp_max = d3.max(data.solution_path, function(d) { return +d.changepoints;});

var spXScale = d3.scaleLinear()
    .domain([sp_cp_min, sp_cp_max]) // input
    .range([xpadding, width - xpadding]);

var sp_val_min = d3.min(data.solution_path, function(d) { return +d.penalty_values;});
var sp_val_max = d3.max(data.solution_path, function(d) { return +d.penalty_values;});

var spYScale = d3.scaleLinear()
							.domain([sp_val_min, sp_val_max])
							.range([height - ypadding, ypadding]);

var mxAxis = d3.axisBottom()
							  .scale(mainXScale);

var myAxis = d3.axisLeft()
							  .scale(mainYScale)

var spxAxis = d3.axisBottom()
							  .scale(spXScale);

var spyAxis = d3.axisLeft()
							  .scale(spYScale)

// Create seperate svgs for each plot
// Main plot
var main_plot = div
  .append("svg")
  .attr("class", "main_plot")
  .attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom)

// Solution Path plot
var solution_plot = div
  .append("svg")
  .attr("class", "solution_path")
  .attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom)

// --------------------------------------- MAIN PLOT -------------------------------------------

var line = d3.line()
            .x(function(d, i) { return mainXScale(i); })
            .y(function(d) { return mainYScale(d); });

main_plot.append("path")
          .datum(data.data_set)
          .attr("class", "main-line")
          .attr("fill", "none")
          .attr("stroke", "#c5c5c5")
          .attr("d", line);

main_plot.append("g")
    .attr("class", "axis axis--x")
    .attr("transform", "translate(0," + height + ")")
    .call(mxAxis);

// text label for the x axis
main_plot.append("text")
      .attr("transform", "translate(" + (width/2) + " ," + (height + margin.top + 5) + ")")
      .style("text-anchor", "middle")
      .text("Time");

main_plot.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + ypadding + ", 0)")
    .call(myAxis);

// text label for the y axis
main_plot.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 0- margin.left/18)
      .attr("x",0 - (height / 2))
      .attr("dy", "1em")
      .style("text-anchor", "middle")
      .text("Value");


// ------------------------------------- Histogram  ---------------------------------------------------

//console.log(d3.values(counts));
main_plot.selectAll(".bar")
      .data(d3.values(counts))
    .enter().append("rect")
      .attr("class", "bar")
      .attr("x", function(d, i) { return mainXScale(i); })
      .attr("width", 2)
      .attr("y", function(d) { return histYScale(d);})
      .attr("height", function(d) { return height - histYScale(d);})
      .style("opacity", 0.6)
      .style("fill", "#ff6f61");

// ------------------------------------- Solution Path --------------------------------------------


var Piecewise_constant = d3.line()
            .x(function(d) { return mainXScale(d.x); })
            .y(function(d) { return mainYScale(d.y); })
            .curve(d3.curveStepAfter);

solution_plot.selectAll("circle")
			   .data(data.solution_path)
			   .enter()
			   .append("circle")
			   .attr("cx", function(d) {
			   		return spXScale(d.changepoints);
			   })
			   .attr("cy", function(d) {
			   		return spYScale(d.penalty_values);
			   })
			   .attr("r", 4)
			   .attr("fill", "#c5c5c5")
			   .on("mouseover", function(d){
			     solution_plot.selectAll("#tooltip").remove();
			     solution_plot.selectAll("#selection_line").remove();
			     solution_plot.selectAll("#selection_circle").remove();
			     solution_plot.selectAll("#focus_circle").remove();
			     main_plot.selectAll("#change_point").remove();
			     main_plot.selectAll(".pc-line").remove();


			     var change_locations = data.cpts_full[changepoint_lengths.indexOf(d.changepoints)].map( function(value) {
                return value - 1;
              } );

          if (change_locations[0] !== 0) {
            change_locations.unshift(0);
          }
          change_locations.push(data.data_set.length-1);

          // split the data into segemnts
			    var segments = [];
			    for (i = 0; i < change_locations.length; i++) {
                let chunk = data.data_set.slice(change_locations[i], change_locations[i + 1]);
                segments.push(chunk);
              }

          // calcualte the mean for each segment of the data
          var means = [];
          for (i = 0; i < segments.length; i++) {
            var sum = 0;
            for (var k = 0; k < segments[i].length; k++){
              sum += parseInt(segments[i][k], 10);
            }
            var avg = sum/segments[i].length;
            means.push(avg);
          }

          // create Piecewise_constant line data
          var pw_c = [];
          for  (var i = 0; i < means.length; i++) {
            pw_c.push({x: change_locations[i], y: means[i]});
          }

			     var xPosition = parseFloat(d3.select(this).attr("cx"))+ 70;
			     var yPosition = parseFloat(d3.select(this).attr("cy")) -10;
			     var lxPosition = parseFloat(d3.select(this).attr("cx"));
			     var lyPosition = parseFloat(d3.select(this).attr("cy"));


          // tooltip penalty value text
			     solution_plot.append("text")
      			     .attr("id", "tooltip")
      			     .attr("x", xPosition)
      			     .attr("y", yPosition)
      			     .attr("text-anchor", "middle")
      			     .attr("font-family", "sans-serif")
      			     .attr("font-weight", "bold")
      			     .attr("font-size", "20px")
      			     .attr("fill", "black")
      			     .text("Pv: " + d.penalty_values)
      			     .style("opacity", 0.6)

            // tooltip changepoint value text
      			solution_plot.append("text")
      			     .attr("id", "tooltip")
      			     .attr("x", lxPosition)
      			     .attr("y", height + 40)
      			     .attr("text-anchor", "middle")
      			     .attr("font-family", "sans-serif")
      			     .attr("font-weight", "bold")
      			     .attr("font-size", "20px")
      			     .attr("fill", "black")
      			     .text(d.changepoints)
      			     .style("opacity", 0.6)

            // selection horizontal line
			     solution_plot.append("line")
			            .attr("id", "selection_line")
      			      .attr("x1", lxPosition - 15)
      			      .attr("y1", lyPosition)
      			      .attr("x2", 0 + ypadding)
      			      .attr("y2", lyPosition)
      			      .attr("stroke", "#ff6f61")
      			      .attr("stroke-width", "3")

            // selection vertical line
      			solution_plot.append("line")
			            .attr("id", "selection_line")
      			      .attr("x1", lxPosition)
      			      .attr("y1", lyPosition + 15)
      			      .attr("x2", lxPosition)
      			      .attr("y2", height)
      			      .attr("stroke", "#ff6f61")
      			      .attr("stroke-width", "3")

      			 solution_plot.append("circle")
      			            .attr("id", "selection_circle")
			                  .attr("cx", lxPosition)
      			            .attr("cy", lyPosition)
      			            .attr("r", 15)
      			            .attr("stroke", "#ff6f61")
      			            .attr("stroke-width", "3")
      			            .attr("fill", "none");

      			 solution_plot.append("circle")
      			            .attr("id", "focus_circle")
			                  .attr("cx", lxPosition)
      			            .attr("cy", lyPosition)
      			            .attr("r", 4)
      			            .attr("fill", "#ff6f61");

      			   main_plot.append("path")
      			          .attr("class", "pc-line")
      			          .attr("d", Piecewise_constant(pw_c))
      			          .style("fill", "none")
      			          .style("stroke", "#ff6f61")
      			          .style("stroke-width", 2);
			   });

solution_plot.append("g")
    .attr("class", "axis axis--x")
    .attr("transform", "translate(0," + height + ")")
    .call(spxAxis);

// text label for the x axis
solution_plot.append("text")
      .attr("transform", "translate(" + (width/2) + " ," + (height + margin.top + 10) + ")")
      .style("text-anchor", "middle")
      .text("Number of Changepoints");


solution_plot.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + ypadding + ", 0)")
    .call(spyAxis);

// text label for the y axis
solution_plot.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 0- margin.left/18)
      .attr("x",0 - (height / 2))
      .attr("dy", "1em")
      .style("text-anchor", "middle")
      .text("Penalty Value");

