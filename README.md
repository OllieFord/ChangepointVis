<h1 align="center">
  <br>
  <img src="https://raw.githubusercontent.com/OllieFord/ChangepointVis/master/images/cpvisLogo.png" alt="cpVis" width="200">
  <br>
  Change Point Visualisation
  <br>
</h1>

<h4 align="center">A Interactive Visualisation for change point exploration and labeling built on top of the <a href="https://github.com/rkillick/changepoint" target="_blank">changepoint package</a>.</h4>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#credits">Credits</a> •
  <a href="#motivation">Motivation</a> •
  <a href="#related-work">Related Work</a> •
  <a href="#project-goals">Project Goals</a> •
  <a href="#license">License</a>
</p>

![screenshot](https://raw.githubusercontent.com/OllieFord/ChangepointVis/master/images/cpvis.gif)

## Key Features

* Changepoint visual exploration
  - Visualise univariate time series data 
  - Automatically compute change points for a range of penalty values 
  - Interactively visualise changepoints for each penalty value 
  - Histogram of means between changepoints
  - General information such as dataset mean, variance and max/min penalty values


## How To Use
ChangepointVis exists as an R package and can be imported as a standard R package using library("CpVis"). Once in RStudio you can use the following commands to get started:

```R
# import the CpVis package
library("CpVis")

# Create a fake univariate dataset (or use your own)
data = c(rnorm(100,0,1),rnorm(100,5,1))

# call the cpVisualise function with a penalty range
cpVisualise(data, penalty_range=c(1e-5,10))

# Interface will now open in a new browser window

```

## Credits

This software uses the following open source packages:

- [changepoint](https://github.com/rkillick/changepoint)
- [d3.js](https://d3js.org/)
- [R2D3](https://github.com/rstudio/r2d3)


## Motivation

A changepoint is typically defined as a point in time where the distribution of a data-stream changes in a distinct manner, for example, typically one may look for changepoints in mean, and/or variance. Usually, this is performed in an unsupervised setting where we have no labelled examples of true changepoints. However, in practice, we usually have examples of periods of time where we know no changes should be present, or conversely where changes are expected to exist. When and where such information is available, we can potentially use this to aid our judgement of how to set complexity penalties in the changepoint estimation task, and thus, decide on an appropriate number of changepoints, a task which currently requires time-consuming parameter tuning by domain experts. Currently, this process is severely hampered by a lack of streamlined tools required for the task, namely, visualisation of changepoint solutions (across tuning parameters), interactive labelling of data-streams, and finally taking this feedback into account when learning penalty functions. 

Taken together these components fall into recent efforts to produce explainable AI systems within the growing community of research that involves 'the human in the loop' to monitor and control complicated algorithms. Such approaches aims to complement the system's capabilities with the contextual domain knowledge, creativity, and decision making capabilities of humans. To help humans understand and control an algorithmic system, interactive visualizations provide a range of potential while leveraging humans' capabilities of parallel and simultaneous perception, pattern detection, as well as exploratory analysis. In this particular project, we seek a simple visualization interface to support, i) human labeling of the data with the aid of several complementary measures on the data-stream such as as mean, trends, min, max, variance, etc. and ii) interactive exploration of the result space suggested by a changepoint detection algorithm. Eventually, any visualization will help communicating the data and respective decisions to peers and larger audiences in the form of reports, posters, slideshows, or open web-documentations.


## Related work

Two key packages related to this work are discussed below:

penaltyLearning - https://cran.r-project.org/web/packages/penaltyLearning/index.html
	Provides a mechanism for learning penalty level for given univariate sequence and labelled changepoint regions. While the package provides a useful method to suggest an optimal penalty level for defining changepoint segmentation it is geared largely towards the genetics community. We aim to utilise the penalty learning method in this package, but integrate this in a more general labelling framework with an enhanced focus on visualisation and interaction. This will allow for quick user comparison between unsupervised and supervised changepoint methods.

changepoint - https://cran.r-project.org/web/packages/changepoint/index.html
	Provides various methods for segmenting individual time-series based on mean and variance. We plan to use the included methods (mainly PELT) to perform unsupervised segmentation, but extend the visualisation of such solutions to enable better interpretation of changepoint output. Experience with end-users suggests it is a time-consuming process to find an appropriate penalty parameter using these methods, in large part due to lack of coherent visualisation of solution paths. There is no labelled/supervised learning capability currently within the changepoint package. The final part of this proposal aims to examine changepoint detection in multivariate series, and use visualisation tools to help highlight changepoints which may be shared across data streams.s

A range of recent work that focuses on interactive visualization of AI systems [1] and can be summarized under the terms 'Explainable' or 'interactive AI'. Examples include interactive playgrounds such as TensorFlow Playground (http://playground.tensorflow.org) and Momentum (https://distill.pub/2017/momentum/), tools for interactive machine learning (https://learningfromusersworkshop.github.io/) as well as more story-like descriptions of studies and analysis cases (http://formafluens.io/client/mix10.html). A great variety of further tools and research is summarized online: http://visxai.io/program.html. More specific, tools such as SmallMultiples [2] and BayesPiles [3] use simple segmentation methods (far less sophisticated than changepoint detection in R) as a proof-of-concept to demonstrate interactive visualization approaches to detect states in temporal networks. In both cases, visualization is used to provide a user with a holistic view of the data (i.e., a time sequence of networks) including more specific information required to aid a user in making decisions about temporal states. Interaction is used complementary to automatic segmentation to allow a user to explore a found segmentation solution (explore states in the network) as well as to quickly refine an automatic solution by splitting and combining states. Finally, time curves [4] are a far more generic way to visualize changes over time, e.g., for multiple timeseries. To the best of our knowledge, no tool and visualization interface exists that allows analysts to explore the solution path of changepoint detection methods in simple and multiple time-series. Through this project, we will lay they foundations for interfaces and methods that enable changepoint detection across a variety of domains 

## Project Goals

- [x] Visualizing relevant information on time series, such as means, trends, etc. for a variety of number of changepoints defined via a penalty threshold.
- [ ] Allow for manual labeling of a time series so that researchers can label time points based on the patterns they see in the data, or prior knowledge. 
- [ ] Use labelling (and max-min labelling) to learn “optimal” penalty levels and provide consistent changepoint/model specification.
- [ ] Extend 1 to work with multiple time series.

## License

GPL

---

