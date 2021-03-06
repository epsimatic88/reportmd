% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.R
\name{plotMD}
\alias{plotMD}
\title{Create plots for inclusion in RMarkdown reports}
\usage{
plotMD(fig, format = knitr::opts_current$get("format"))
}
\arguments{
\item{fig}{A ggplot2 plot for processing.}

\item{format}{A character vector of length one describing the desired
output format.}
}
\value{
Depending on the value of \code{format} either a ggplot2 object
 (possibly the same as \code{fig}) or, if \code{format = 'interactive'}
 a \code{plotly} plot.
}
\description{
Create plots for inclusion in RMarkdown reports
}
\examples{
\dontrun{
 library(ggplot2)
 library(plotly)
 fig <- ggplot(cars, aes(x=speed, y=dist)) + geom_point()
 plotMD(fig, format='s') ## uses ggplot2
 plotMD(fig, format='i') ## uses plotly

}
}
\author{
Peter Humburg
}
\seealso{
\code{\link[plotly]{ggplotly}}
}

