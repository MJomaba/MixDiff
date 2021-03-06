% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MCMC.R
\name{plot_parameter_chains}
\alias{plot_parameter_chains}
\title{Plots the MCMC chains of parameters}
\usage{
plot_parameter_chains(MCMCres, theta_true = NULL)
}
\arguments{
\item{MCMCres}{The output of function \code{\link{RunMCMC}}.}

\item{theta_true}{A list of parameters to which the output chains should be compared. If not \code{NULL}, this should contain:
\itemize{
 \item{\code{mu}}{: A list of length \code{n_groups=length(MCMCres$aug_dat_chain[[1]]$D)}. Each element of \code{mu} should be a scalar or vector giving the mean delay(s) in that group.}
 \item{\code{CV}}{: A list of length \code{n_groups}. Each element of \code{CV} should be a scalar or vector giving the coefficient o variation of the delay(s) in that group.}
 \item{\code{zeta}}{: A scalar in [0;1] giving the probability that, if a data point is not missing, it is recorded with error.}
}}
}
\value{
Nothing. Only performs a plot.
}
\description{
Plots the MCMC chains of parameters
}
\examples{
### TO WRITE OR ALTERNATIVELY REFER TO VIGNETTE TO BE WRITTEN ###
}
