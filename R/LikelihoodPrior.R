###############################################
### likelihood function ###
###############################################

LL_observation_term_by_group_delay_and_indiv <- function(aug_dat, theta, obs_dat, group_idx, date_idx, indiv_idx, range_dates=NULL)
{
  if(is.null(range_dates)) range_dates <- find_range(obs_dat)
  LL <- matrix(NA, length(indiv_idx), length(date_idx))
  ### making sure D=y if E=0 ### note could remove this if by construction this is always true - could speed up code
  indicator_no_error <- aug_dat$E[[group_idx]][indiv_idx, date_idx] == 0
  no_error <- which(indicator_no_error, arr.ind = TRUE)
  LL[no_error] <- log(aug_dat$D[[group_idx]][indiv_idx, date_idx][no_error] == obs_dat[[group_idx]][indiv_idx, date_idx][no_error]) 
  ### if E=1, what is the relationship between true date D and observed date y
  # for now, observation likelihood conditional on E=1 is uniform on the range of observed dates
  ### same for E=-1, D can take any value in range with same probability as they are all consistent with y=NA
  error_or_missing <- which(!indicator_no_error)
  ### K is the relative probability of observing a given error, conditional on presence of error
  # for now, K is given as 1/n, where n is the number of dates in the range_dates
  # could use something different if we define the space of possible errors differently. 
  ### think about impact of this choice
  K <- (1/as.numeric(diff(range_dates)))
  LL[error_or_missing] <- log( K* ((aug_dat$D[[group_idx]][indiv_idx, date_idx][error_or_missing] >= range_dates[1]) & (aug_dat$D[[group_idx]][indiv_idx, date_idx][error_or_missing] <= range_dates[2])) ) 
  
  LL[is.infinite(LL)] <- -100000 # arbitrarily small number to avoid -Inf
  
  return(LL)
}

LL_observation_term<-function(aug_dat, theta, obs_dat, range_dates=NULL)
{
  if(is.null(range_dates)) range_dates <- find_range(obs_dat)
  LL <- sum(unlist(lapply(seq_len(length(obs_dat)), function(g) sum(LL_observation_term_by_group_delay_and_indiv(aug_dat, theta, obs_dat, g, seq_len(ncol(aug_dat$D[[g]])), seq_len(nrow(obs_dat[[g]])), range_dates)) ) ))
  return(LL)
}
# LL_observation_term(aug_dat, theta, obs_dat)

LL_error_term_by_group_delay_and_indiv <- function(aug_dat, theta, obs_dat, group_idx, date_idx, indiv_idx)
{
  res <- matrix(0, length(indiv_idx), length(date_idx))
  non_missing <- which(aug_dat$E[[group_idx]][indiv_idx,date_idx] != -1, arr.ind = TRUE)
  tmp <- aug_dat$E[[group_idx]][indiv_idx,date_idx][non_missing]
  res[non_missing] <- log(theta$zeta)*tmp + log(1-theta$zeta)*(1-tmp)
  return(res)
}

compute_n_errors <- function(aug_dat, obs_dat)
{
  number_of_errors <- sum(unlist(aug_dat$E) == 1)
  number_of_recorded_dates <- sum(unlist(aug_dat$E) != -1)
  return(c(number_of_errors, number_of_recorded_dates))
}
# system.time(compute_n_errors(aug_dat, obs_dat))

LL_error_term<-function(aug_dat, theta, obs_dat)
{
  tmp <- compute_n_errors(aug_dat, obs_dat)
  number_of_errors <- tmp[1]
  number_of_recorded_dates <- tmp[2]
  #result<-dbinom(number_of_errors,number_of_recorded_dates,theta$zeta,log=TRUE)
  result<- log(theta$zeta)*number_of_errors + log(1-theta$zeta)*(number_of_recorded_dates-number_of_errors) ### not incorporating the binomial coefficient as we knoe exactly which ones are with and without error
  
  return(result)
}
# system.time(LL_error_term(aug_dat, theta, obs_dat))

#LL_error_term_slow<-function(aug_dat, theta, obs_dat)
#{
#  LL <- sum (sapply(seq_len(n_groups), function(g) sum ((LL_error_term_by_group_delay_and_indiv(aug_dat, theta, obs_dat, g, seq_len(ncol(aug_dat$D[[g]])), seq_len(nrow(obs_dat[[g]]))) ) ) ) )
#  return(LL)
#}
# system.time(LL_error_term_slow(aug_dat, theta, obs_dat))

####################################
# discretised Gamma distribution - see Cori et al. AJE 2013
####################################

DiscrGamma <- function (k, mu, CV = NULL, sigma = mu*CV, log=TRUE) 
{
  if (!is.null(CV)) {
    if(CV < 0)
      stop("CV must be >=0.")
  }
  if (sigma < 0) {
    stop("sigma must be >=0.")
  }
  shape <- (mu/sigma)^2
  rate <- mu/(sigma^2)
  
  res <- (k + 1) * pgamma(k + 1, shape, rate) + (k - 1) * pgamma(k - 1, shape, rate) - 2 * k * pgamma(k, shape, rate)
  
  res <- res + (shape / rate) * (2 * pgamma(k, shape + 1, rate) - pgamma(k - 1, shape + 1, rate) - pgamma(k + 1, shape + 1, rate))
  
  res <- pmax(0, res)
  
  return(if(log) log(res) else res)
}

# DiscrGamma_approx <- function (k, mu, CV = NULL, sigma=mu*CV, log=TRUE) 
# {
#   if (!is.null(CV)) {
#     if(CV < 0)
#       stop("CV must be >=0.")
#   }
#   if (sigma < 0) {
#     stop("sigma must be >=0.")
#   }
#   shape <- (mu/sigma)^2
#   rate <- mu/(sigma^2)
#   
#   res <- distcrete::distcrete("gamma", 1, shape, rate, w = 0.5)$d(k)
#   return(if(log) log(res) else res)
# }

LL_delays_term_by_group_delay_and_indiv <- function(aug_dat, theta, obs_dat, group_idx, delay_idx, indiv_idx, index_dates, Delta=NULL)
{
  if(is.null(Delta)) Delta <- compute_delta_group_delay_and_indiv(aug_dat$D, group_idx, indiv_idx, delay_idx, index_dates)
  LL <- DiscrGamma(Delta, mu=theta$mu[[group_idx]][delay_idx], CV=theta$CV[[group_idx]][delay_idx], log=TRUE)
  return(LL)
}

LL_delays_term<-function(aug_dat, theta, obs_dat, index_dates, Delta=NULL)
{
  if(is.null(Delta)) Delta <- compute_delta(aug_dat$D, index_dates)
  LL <- sum (sapply(seq_len(length(obs_dat)), function(g) sum (sapply(seq(2, ncol(aug_dat$D[[g]]), 1), function(j) sum(LL_delays_term_by_group_delay_and_indiv(aug_dat, theta, obs_dat, g, j-1, seq_len(nrow(obs_dat[[g]])), index_dates, Delta[[g]][seq_len(nrow(obs_dat[[g]])), j-1])) ) ) ) )
  return(LL)
}
# LL_delays_term(aug_dat, theta, obs_dat)

LL_total <- function(aug_dat, theta, obs_dat, index_dates, range_dates=NULL)
{
  res <- LL_observation_term(aug_dat, theta, obs_dat, range_dates) + 
    LL_error_term(aug_dat, theta, obs_dat) + 
    LL_delays_term(aug_dat, theta, obs_dat, index_dates)
  return(res)
}
# LL_total(aug_dat, theta, obs_dat)

###############################################
### priors ###
###############################################

# zeta ~ beta(low mean) # need a very informative prior
lprior_prob_error <- function(theta, hyperparameters) 
{
  # can use this code to plot the corresponding prior: 
  # x <- seq(0,1,0.01)
  # y <- dbeta(x, hyperparameters$shape1_prob_error,  hyperparameters$shape2_prob_error)
  # plot(x, y, type="l")
  return(dbeta(theta$zeta, hyperparameters$shape1_prob_error,  hyperparameters$shape2_prob_error, log = TRUE))
}
# param_beta <- find_params_beta(mean=0.2, var=0.01)
# lprior_prob_error(theta, list(shape1_prob_error=param_beta[1], shape2_prob_error=param_beta[2]))

# mu and CV ~ Exp(mean 1000) # very informative prior should be ok because data will be informative
lprior_params_delay <- function(what=c("mu", "CV"), theta, hyperparameters) # using the same prior for the mean of all delays
{
  what <- match.arg(what)
  # can use this code to plot the corresponding prior: 
  # x <- seq(0,1000,1)
  # y <- dexp(x, 1/hyperparameters$mean_mean_delay)
  # plot(x, y, type="l")
  return(sum(dexp(unlist(theta[[what]]), 1/hyperparameters$mean_mean_delay, log = TRUE)))
}
#lprior_params_delay("mu", theta, list(mean_mean_delay=10))

lprior_total <- function(theta, hyperparameters)
{
  res <- lprior_prob_error(theta, hyperparameters) + 
    lprior_params_delay("mu", theta, hyperparameters) + 
    lprior_params_delay("CV", theta, hyperparameters)
  return(res)
}
#lprior_total(theta, list(shape1_prob_error=3, shape2_prob_error=12, mean_mean_delay=100, mean_CV_delay=100))

###############################################
### posteriors ###
###############################################

#' Compute the log joint posterior distribution of augmented data and parameters given observed data
#' 
#' @param aug_dat A list of augmented data, in the format of the first element (called \code{true_dat}) in the list returned by \code{\link{simul_true_data}}. 
#' @param theta List of parameters; see details.
#' @param obs_dat A list of observed data, in the format of the first element (called \code{obs_dat}) in the list returned by \code{\link{simul_obs_dat}}. 
#' @param hyperparameters A list of hyperparameters: see details.
#' @param index_dates A list containing indications on which delays to consider in the estimation, see details.
#' @param range_dates A vector containing the range of dates in \code{obs_dat}. If NULL, will be computed automatically.
#' @details \code{theta} should be a list containing:
#' \itemize{
#'  \item{\code{mu}}{: A list of length \code{n_groups} (the number of groups to be simulated data). Each element of \code{mu} should be a scalar of vector giving the mean delay(s) to use for simulation of dates in that group.}
#'  \item{\code{CV}}{: A list of length \code{n_groups}. Each element of \code{CV} should be a scalar of vector giving the coefficient o variation of the delay(s) to use for simulation of dates in that group.}
#'  \item{\code{zeta}}{: A scalar in [0;1] giving the probability that, if a data point is not missing, it is recorded with error.}
#' }
#' \code{hyperparameters} should be a list containing:
#' \itemize{
#'  \item{\code{shape1_prob_error}}{: A scalar giving the first shape parameter for the beta prior used for parameter \code{theta$zeta}}
#'  \item{\code{shape2_prob_error}}{: A scalar giving the second shape parameter for the beta prior used for parameter \code{theta$zeta}}
#'  \item{\code{mean_mean_delay}}{: A scalar giving the mean of the exponential prior used for parameter \code{theta$mu}}
#'  \item{\code{mean_CV_delay}}{: A scalar giving the mean of the exponential prior used for parameter \code{theta$CV}}
#' }
#' \code{index_dates} should be a list of length \code{n_groups=length(obs_dat)}. Each element of \code{index_dates} should be a matrix with 2 rows and a number of columns corresponding to the delays of interest for that group. For each column (i.e. each delay), the first row gives the index of the origin date, and the second row gives the index of the destination date. 
#' The number of columns of index_dates[[k]] should match the length of theta$mu[[k]] and theta$CV[[k]] 
#' 
#' If index_dates[[k]] has two columns containing respectively c(1, 2) and c(1, 3), this indicates that theta$mu[[k]] and theta$CV[[k]] are respectively the mean and coefficient of variation of two delays: the first delay being between date 1 and date 2, and the second being between date 1 and date 3. 
#' @return A scalar giving the value of the log posterior. 
#' @export
#' @examples
#' ### Number of groups of individuals to simulate ###
#' n_groups <- 2
#' ### Number of dates to simulate for each group ###
#' n_dates <- c(2, 3)
#' ### Setting up the parameters for the simulation ###
#' theta <- list()
#' theta$mu <- list(5, c(10, 15)) # mean delays, for each group
#' theta$CV <- list(0.5, c(0.5, 0.5)) # coefficient of variation of these delays
#' theta$prop_missing_data <- 0.25 # probability of data missing in observations
#' theta$zeta <- 0.05 # probability that, when not missing, the date is recorded with error
#' ### Number of individuals to simulate in each group ###
#' n_per_group <- rep(10, n_groups)
#' ### Range of dates in which to draw the first set of dates for each group ###
#' range_dates <- date_to_int(c(as.Date("01/01/2014", "%d/%m/%Y"), as.Date("01/01/2015", "%d/%m/%Y")))
#' ### Which delays to use to simulate subsequent dates from the first, in each group? ###
#' index_dates <- list(matrix(c(1, 2), nrow=2), cbind(c(1, 2), c(1, 3)))
#' ### Simulate data ###
#' D <- simul_true_data(theta, n_per_group, range_dates, index_dates)
#' observed_D <- simul_obs_dat(D$true_dat, theta, range_dates, remove_allNA_indiv=TRUE)
#' obs_dat <- observed_D$obs_dat
#' true_aug_dat <- list(D=D$true_dat, E=observed_D$E)
#' ### Define hyperparameters ###
#' hyperparameters <- list(shape1_prob_error=3, shape2_prob_error=12, 
#'                      mean_mean_delay=100, mean_CV_delay=100)
#' ### Compute log posterior distribution for that data
#' lposterior_total(true_aug_dat, theta, obs_dat, hyperparameters, index_dates, range_dates=NULL)
#' ### Now use initalised augmented data 
#' ### and check that posterior value for this is lower than for true data:
#' MCMC_settings <- list(init_options=list(mindelay=0, maxdelay=100))
#' aug_dat <- initialise_aug_data(observed_D$obs_dat, index_dates, MCMC_settings)
#' lposterior_total(aug_dat, theta, obs_dat, hyperparameters, index_dates, range_dates=NULL)
lposterior_total <- function(aug_dat, theta, obs_dat, hyperparameters, index_dates, range_dates=NULL)
{
  res <- LL_total(aug_dat, theta, obs_dat, index_dates, range_dates) + lprior_total(theta, hyperparameters)
  return(res)
}
#lposterior_total(aug_dat, theta, obs_dat, hyperparameters=list(shape1_prob_error=3, shape2_prob_error=12, mean_mean_delay=100, mean_CV_delay=100))