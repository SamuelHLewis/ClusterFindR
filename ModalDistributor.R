#!/usr/bin/env Rscript

suppressPackageStartupMessages(library("argparse"))

##############################################################################################
# function to create a distribution with a fixed sample size and a specified number of modes #
##############################################################################################
ModalDistributor <- function(userSampleSize, userMean, userStandardDeviation, userModes, userInterval){
  # empty vector for distribution values
  userDistribution <- vector()
  # set mean for 1st loop to user selection
  currentMean <- userMean
  # for each mode...
  for (i in seq(1:userModes)){
    # sample a fraction of the total sample size (according to number of modes requested), using incremented mean after first loop
    userDistribution <- c(userDistribution, rnorm(userSampleSize/userModes, mean = currentMean, sd = userStandardDeviation))
    # increment mean by user-defined interval
    currentMean <- currentMean + userInterval
  }
  # if the number of samples is less than the user-defined sample size (usually because an odd number of modes was specified), add final entries based on the most recent parameters
  if (length(userDistribution) < userSampleSize){
    userDistribution <- c(userDistribution, rnorm(userSampleSize - length(userDistribution), mean = currentMean - userInterval, sd = userStandardDeviation))
  }
  return(userDistribution)
}

#########################
# user argument parsing #
#########################
# create parser object
parser <- ArgumentParser()
# parse sample size
parser$add_argument("-n", "--sampleSize", type = "integer", help = "Sample size for distribution")
# parse mean
parser$add_argument("-a", "--mean", type = "double", help = "Mean of first distribution")
# parse sd
parser$add_argument("-s", "--standardDeviation", type = "double", help = "Standard deviation for all distributions")
# parse modes
parser$add_argument("-m", "--modes", type = "integer", help = "Number of modes in distribution")
# parse interval
parser$add_argument("-i", "--interval", type = "double", help = "Interval between modes (not used if modes < 2)")
# collect arguments
args <- parser$parse_args()
# generate distribution
output <- ModalDistributor(userSampleSize = args$sampleSize, userMean = args$mean, userStandardDeviation = args$standardDeviation, userModes = args$modes, userInterval = args$interval)
# output values to file
writeLines(text=as.character(output), con = "Distribution.txt")
