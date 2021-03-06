% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MCMC.R
\name{get_param_posterior_estimates}
\alias{get_param_posterior_estimates}
\title{Computes posterior estimates of parameters from the MCMC chain}
\usage{
get_param_posterior_estimates(MCMCres, central = c("median", "mean"),
  CrI = 0.95, theta_true = NULL, plot = TRUE, cex.axis = 1)
}
\arguments{
\item{MCMCres}{The output of function \code{\link{RunMCMC}}.}

\item{central}{A character specifying what the central estimate should be (median or mean posterior)}

\item{CrI}{A scalar in [0;1] used to compute the posterior credible intervals. For 95\% credible intervals, use CrI=0.95.}

\item{theta_true}{A list of parameters to which the output chains should be compared. If not \code{NULL}, this should contain:
\itemize{
 \item{\code{mu}}{: A list of length \code{n_groups=length(MCMCres$aug_dat_chain[[1]]$D)}. Each element of \code{mu} should be a scalar or vector giving the mean delay(s) in that group.}
 \item{\code{CV}}{: A list of length \code{n_groups}. Each element of \code{CV} should be a scalar or vector giving the coefficient o variation of the delay(s) in that group.}
 \item{\code{zeta}}{: A scalar in [0;1] giving the probability that, if a data point is not missing, it is recorded with error.}
}
The posterior distributions of parameters are then plotted together with \code{theta_true}.}

\item{plot}{A boolean specifying whether to plot boxplots of the posterior estimates or not}

\item{cex.axis}{A numerical value giving the amount by which x axis labels should be magnified relative to the default.}
}
\value{
A list containing two elements: the posterior estimates of parameters:
\itemize{
 \item{\code{logpost}}{: A vector of three values giving the central log-posterior estimate (first value) and quantiles corresponding to CrI (second and third values). }
 \item{\code{theta}}{: A list giving posterior parameter estimates
 \itemize{
 \item{\code{mu}}{: A list of length \code{n_groups=length(MCMCres$aug_dat_chain[[1]]$D)}. Each element of \code{mu} should be a matrix with 3 rows giving the posterior mean delay(s) in that group (1st row = central posterior estimate, 2nd and 3rd rows = credible interval) .}
 \item{\code{CV}}{: A list of length \code{n_groups}. Each element of \code{CV} should be a matrix with 3 rows giving the posterior CV of the delay(s) in that group (1st row = central posterior estimate, 2nd and 3rd rows = credible interval) .}
 \item{\code{zeta}}{: A vector of three values in [0;1] giving the posterior estimate of the probability that, if a data point is not missing, it is recorded with error (1st value = central posterior estimate, 2nd and 3rd values = credible interval).}
 }
 }
}
}
\description{
Computes posterior estimates of parameters from the MCMC chain
}
\examples{
### TO WRITE OR ALTERNATIVELY REFER TO VIGNETTE TO BE WRITTEN ###
}
