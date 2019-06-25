// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)
//
// r2d3: https://rstudio.github.io/r2d3
//

var data = r2d3.data;

const accent_colour = "#4363d8"; //blue
const base_colour = "#c5c5c5"; //Grey
const secondary_colour = "#f58231"; //orange

// ---------------- Convert data  ---------------------
// data manipulation on startup -(these are quality of life changes)

var changepoint_lengths = [];
for (i = 0; i < data.cpts_full.length; i++) {
  changepoint_lengths.push(data.cpts_full[i].length);
}

//console.log(changepoint_lengths);

// new cpts_full data  (to, changed to index at zero)
all_changepoints = [];
for (i = 0; i < data.cpts_full.length; i++) {
  var change_locations = [];
  for (j = 0; j < data.cpts_full[i].length; j++) {
    change_locations.push(data.cpts_full[i][j] - 1);
  }
  if (change_locations[0] !== 0) {
    change_locations.unshift(0);
  }
  change_locations.push(data.data_set.length-1);
  all_changepoints.push(change_locations);
}

// compute count of all changepoints
var counts = {};
for (var i = 0; i < all_changepoints.length; i++) {
  for(var j=0; j< all_changepoints[i].length; j++){
    var num = all_changepoints[i][j];
    counts[num] = counts[num] ? counts[num] + 1 : 1;
  }
}

var counts_keys = d3.keys(counts);
var counts_values = d3.values(counts);
//var scaled_counts = counts_values.map(function(x) x * d3.max(counts_values));

var hist_data = [];
for (i = 0; i < counts_values.length; i++) {
  var tmp = {loc:counts_keys[i], count:counts_values[i] };
  hist_data.push(tmp);
}


var data_table = [];

// ---------------- Plot Layout Parameters ---------------------

var parentDiv = document.getElementById("main_output");
var width = parentDiv.clientWidth;
var height = parentDiv.clientHeight;
var margin = {top: 50, right: 50, bottom: 30, left: 0};


var xpadding = 60;
var ypadding = 90;

// ---------------- Setup scales ---------------------
var mainXScale = d3.scaleLinear()
    .domain([0, data.data_set.length-1]) // input
    .range([xpadding+5, width - xpadding]).nice();

var mainYScale = d3.scaleLinear()
							.domain([d3.min(data.data_set), d3.max(data.data_set)])
							.range([height - ypadding, 5]).nice();

var histYScale = d3.scaleLinear()
							.domain([d3.min(counts_values), d3.max(counts_values)])
							.range([height,  height - ypadding]).nice();

var sp_cp_min = d3.min(data.solution_path, function(d) { return +d.numberofchangepoints - 1;});
var sp_cp_max = d3.max(data.solution_path, function(d) { return +d.numberofchangepoints - 1;});

var spXScale = d3.scaleLinear()
    .domain([sp_cp_min, sp_cp_max]) // input
    .range([xpadding+5, width - xpadding]).nice();

var sp_val_min = d3.min(data.solution_path, function(d) { return +d.beta_interval;});
var sp_val_max = d3.max(data.solution_path, function(d) { return +d.beta_interval;});

var spYScale = d3.scaleLinear()
							.domain([sp_val_min, sp_val_max])
							.range([height - ypadding, 25]).nice();

var mxAxis = d3.axisBottom()
							  .scale(mainXScale);

var myAxis = d3.axisLeft()
							  .scale(mainYScale)

var spxAxis = d3.axisBottom()
							  .scale(spXScale);

var spyAxis = d3.axisLeft()
							  .scale(spYScale)

// ---------------- Setup plot elements ---------------------

// Create seperate svgs for each plot
// Main plot
var main_plot = div
  .append("svg")
  .attr("class", "main_plot")
  .attr("viewBox", "0 0 "+  (width + margin.left + margin.right) +" " + (height + margin.top + margin.bottom))
  //.attr("width", width + margin.left + margin.right)
  //.attr("height", height + margin.top + margin.bottom)

// Solution Path plot
var solution_plot = div
  .append("svg")
  .attr("class", "solution_path")
  .attr("viewBox", "0 0 "+  (width + margin.left + margin.right) +" " + (height + margin.top + margin.bottom))

var info = d3.select(".info")
var m_hist = d3.select("#mean_hist"),
    mwidth = +m_hist.attr("width"),
    mheight = +m_hist.attr("height")

var mean_hist_div = document.getElementById("mean_hist");
var mh_width = mean_hist_div.clientWidth;
var mh_height = mean_hist_div.clientHeight;
var mh_margin = {top: 50, right: 50, bottom: 50, left: 50};

// necesary for plot reszies (if removed plots duplicate)
info.selectAll(".chart").remove();
m_hist.selectAll(".mean_histogram").remove();

var info_plot = info
        .append("div")
        .attr("class", "chart")
        .attr("width", (width / 4) + margin.left - margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .style("border-radius", "2px")
        .style("box-shadow", "0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24)")

var mean_hist = m_hist
        .append("svg")
        .attr("class", "mean_histogram")
        .attr("width", mh_width)
        .attr("height", mh_height)
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
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(mxAxis);

// text label for the x axis
main_plot.append("text")
      .attr("transform", "translate(" + (width/2) + " ," + (height + margin.top + 5) + ")")
      .style("text-anchor", "middle")
      .attr("font-size", "2rem")
      .text("Time");

main_plot.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + xpadding + ", 0)")
    .call(myAxis);

// text label for the y axis
main_plot.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 0- margin.left/18)
      .attr("x",0 - (height / 2))
      .attr("dy", "1em")
      .style("text-anchor", "middle")
      .attr("font-size", "2rem")
      .text("Value");
/*
main_plot.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 0- margin.left/16)
      .attr("x",0 - (height /1.2))
      .attr("dy", "1em")
      .style("text-anchor", "middle")
      .attr("font-size", "1rem")
      .text("Total Changepoint Frequency");
*/

// ------------------------------------- "changepoint freqency"  ---------------------------------------------------
main_plot.selectAll(".bar")
      .data(hist_data)
    .enter().append("rect")
      .attr("class", "bar")
      .attr("x", function(d) { return mainXScale(d.loc) })
      .attr("width", 2)
      .attr("y", function(d) { return histYScale(d.count);})
      .attr("height", function(d) { return height - histYScale(d.count);})
      .style("opacity", 0.3)
      .style("fill", secondary_colour);


// ------------------------------------- info table --------------------------------------------

var table = d3.select(".chart").append('table').attr("class", "table table-borderless");
var thead = table.append('thead');
var	tbody = table.append('tbody');

thead.append('tr')
	.selectAll('th')
	.data(['Variable','Value']).enter()
	.append('th')
	.text(function (col_names) { return col_names; });

var rows = tbody.selectAll('tr')
  		.data(data.d_info)
      .enter()
      .append('tr')
      	.attr("class",function(d) { return d.ind; });
  // add first two columns
rows.append('td').text(function(d) { return d.ind; });
rows.append('td').text(function(d) { return d.values; });



// ------------------------------------- means histogram --------------------------------------------


var mean_hist_x = d3.scaleLinear()
    .domain([d3.min(data.data_set), d3.max(data.data_set)])
    .range([mh_margin.left, mh_width- mh_margin.right]).nice();

var mean_hist_y = d3.scaleLinear()
    .range([mh_height - mh_margin.bottom, mh_margin.top]).nice();

mean_hist.append("g")
    .attr("class", "axis hist_x_axis")
    .attr("transform", "translate(0," + (mh_height - mh_margin.bottom) + ")")
    .call(d3.axisBottom(mean_hist_x))

mean_hist.append("text")
      .attr("transform", "translate(" + (mh_width/2) + " ," + (mh_height - 5) + ")")
      .style("text-anchor", "middle")
      .attr("font-size", "1.5rem")
      .text("Mean's");

mean_hist.append("g")
    .attr("class", "axis hist_y_axis")
    .attr("transform", "translate(" + mh_margin.left + ",0)")
    .call(d3.axisLeft(mean_hist_y).ticks(null, "%"));

// ------------------------------------- Solution Path --------------------------------------------

solution_plot.selectAll("circle")
			   .data(data.solution_path)
			   .enter()
			   .append("circle")
			   .attr("cx", function(d) {
			   		return spXScale((d.numberofchangepoints -1));
			   })
			   .attr("cy", function(d) {
			   		return spYScale(d.beta_interval);
			   })
			   .attr("r", 4)
			   .attr("fill", base_colour)
			   .on("mouseover", function(d){
			     solution_plot.selectAll("#tooltip").remove();
			     solution_plot.selectAll("#selection_line").remove();
			     solution_plot.selectAll("#selection_circle").remove();
			     solution_plot.selectAll("#focus_circle").remove();
			     main_plot.selectAll("#change_point").remove();
			     main_plot.selectAll(".pc-means").remove();
			     mean_hist.selectAll(".hist_update").remove();
			     mean_hist.selectAll(".hist_y_axis").remove();

			     var filtered_change_location = all_changepoints[changepoint_lengths.indexOf((d.numberofchangepoints -1))];


          // split the data into segemnts
			    var segments = [];
			    for (i = 0; i < filtered_change_location.length-1; i++) {
			      if (i > 0) {
			        var chunk = data.data_set.slice(filtered_change_location[i]+1, filtered_change_location[i+1]+1);
			      } else {
			        var chunk = data.data_set.slice(filtered_change_location[i], filtered_change_location[i+1]+1);
			      }
                segments.push(chunk);
              }

          //console.log(JSON.stringify(data.data_set));

          //console.log(JSON.stringify(segments));

          // calcualte the mean for each segment of the data
          var means = [];
          for (i = 0; i < segments.length; i++) {
            var sum = 0;
            for (var k = 0; k < segments[i].length; k++){
              sum += parseFloat(segments[i][k]);
            }
            var avg = sum/segments[i].length;
            means.push(avg);
          }

          //console.log(JSON.stringify(means));

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
      			     .text("Pv: " + d.beta_interval)
      			     .style("opacity", 0.6)

            // tooltip changepoint value text
      			solution_plot.append("text")
      			     .attr("id", "tooltip")
      			     .attr("x", lxPosition)
      			     .attr("y", height - margin.bottom)
      			     .attr("text-anchor", "middle")
      			     .attr("font-family", "sans-serif")
      			     .attr("font-weight", "bold")
      			     .attr("font-size", "20px")
      			     .attr("fill", "black")
      			     .text((d.numberofchangepoints - 1))
      			     .style("opacity", 0.6)

      		solution_plot.append("text")
      			     .attr("id", "tooltip")
      			     .attr("x", (lxPosition + 90))
      			     .attr("y", height - margin.bottom)
      			     .attr("text-anchor", "middle")
      			     .attr("font-family", "sans-serif")
      			     .attr("font-weight", "bold")
      			     .attr("font-size", "20px")
      			     .attr("fill", "black")
      			     .text((d.penalised_cost))
      			     .style("opacity", 0.6)

            // selection horizontal line
			     solution_plot.append("line")
			            .attr("id", "selection_line")
      			      .attr("x1", lxPosition - 15)
      			      .attr("y1", lyPosition)
      			      .attr("x2", 0 + xpadding)
      			      .attr("y2", lyPosition)
      			      .attr("stroke", accent_colour)
      			      .attr("stroke-width", "2")

            // selection vertical line
      			solution_plot.append("line")
			            .attr("id", "selection_line")
      			      .attr("x1", lxPosition)
      			      .attr("y1", lyPosition + 15)
      			      .attr("x2", lxPosition)
      			      .attr("y2", height - ypadding + 17)
      			      .attr("stroke", accent_colour)
      			      .attr("stroke-width", "2")

      			 solution_plot.append("circle")
      			            .attr("id", "selection_circle")
			                  .attr("cx", lxPosition)
      			            .attr("cy", lyPosition)
      			            .attr("r", 15)
      			            .attr("stroke", accent_colour)
      			            .attr("stroke-width", "2")
      			            .attr("fill", "none");

      			 solution_plot.append("circle")
      			            .attr("id", "focus_circle")
			                  .attr("cx", lxPosition)
      			            .attr("cy", lyPosition)
      			            .attr("r", 4)
      			            .attr("fill", accent_colour);

              // piecewise constant lines
      			 for (i = 0; i< means.length; i++){
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
      			          .style("stroke-width", 3);
      			 }





      			 var n = means.length,
                 bins = d3.histogram().domain(mean_hist_x.domain()).thresholds(50)(means),
                 density = kernelDensityEstimator(kernelEpanechnikov(3), mean_hist_x.ticks(50))(means);
            console.log(d3.max(bins, function(d) { return d.length; }));

            mean_hist_y.domain([0, (1/ d3.max(bins, function(d) { return d.length; }))])

            mean_hist.append("g")
                    .attr("class", "axis hist_y_axis")
                    .attr("transform", "translate(" + mh_margin.left + ",0)")
                    .call(d3.axisLeft(mean_hist_y).ticks(null, "%"));

            mean_hist.insert("g", "*")
                .attr("fill", accent_colour)
              .selectAll("rect")
              .data(bins)
              .enter().append("rect")
                .attr("class", "hist_update")
                .attr("x", function(d) { return mean_hist_x(d.x0) + 1; })
                .attr("y", function(d) { return mean_hist_y(d.length / n); })
                .attr("width", function(d) { return mean_hist_x(d.x1) - mean_hist_x(d.x0) - 1; })
                .attr("height", function(d) { return mean_hist_y(0) - mean_hist_y(d.length / n); });


            mean_hist.append("path")
                .datum(density)
                .attr("class", "hist_update")
                .attr("fill", "none")
                .attr("stroke", "#000")
                .attr("stroke-width", 1.5)
                .attr("stroke-linejoin", "round")
                .attr("d",  d3.line()
                    .curve(d3.curveBasis)
                    .x(function(d) { return mean_hist_x(d[0]); })
                    .y(function(d) { return mean_hist_y(d[1]); }));
			   });


function kernelDensityEstimator(kernel, X) {
  return function(V) {
    return X.map(function(x) {
      return [x, d3.mean(V, function(v) { return kernel(x - v); })];
    });
  };
}

function kernelEpanechnikov(k) {
  return function(v) {
    return Math.abs(v /= k) <= 1 ? 0.75 * (1 - v * v) / k : 0;
  };
}

solution_plot.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + (height - ypadding + 17) + ")")
    .attr("font-size", "2rem")
    .call(spxAxis);

// text label for the x axis
solution_plot.append("text")
      .attr("transform", "translate(" + (width/2) + " ," + (height) + ")")
      .style("text-anchor", "middle")
      .attr("font-size", "2rem")
      .text("Number of Changepoints");


solution_plot.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + xpadding + ", 0)")
    .attr("font-size", "2rem")
    .call(spyAxis);

// text label for the y axis
solution_plot.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 0- margin.left/18)
      .attr("x",0 - (height / 2))
      .attr("dy", "1em")
      .style("text-anchor", "middle")
      .attr("font-size", "2rem")
      .text("Penalty Value");

