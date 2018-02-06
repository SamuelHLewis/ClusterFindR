#!/usr/bin/env Rscript

# this code is adapted from the University of Cambridge Introduction to Machine Learning course (https://github.com/bioinformatics-training/intro-machine-learning-2017/blob/master/09-clustering.Rmd)

suppressPackageStartupMessages(library("argparse"))
suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("RColorBrewer"))
suppressPackageStartupMessages(library("cluster"))

#########################
# user argument parsing #
#########################
# create parser object
parser <- ArgumentParser()
# parse input table
parser$add_argument("-i", "--input", type = "character", help = "Input data table (must have a header, and missing data must be marked with \".\")")
# parse explanatory variable
parser$add_argument("-v", "--variable", type = "character", help = "Variable to use for clustering (must be a unique exact match to a header in the input data)")
# parse number of clusters
parser$add_argument("-k", "--clusters", type = "integer", help = "Maximum number of clusters")
# collect arguments
args <- parser$parse_args()
# assign arguments to variables
userInput <- args$input
userVariable <- args$variable
clusterMax <- args$clusters

# read in data
dat <- read_csv(userInput, na = ".")
# find column number in input data that corresponds to the user variable (because this has to be used to call the data from this column later on, rather than using the column name)
for (i in seq(1:length(names(dat)))){
  if (names(dat)[i] == userVariable){
    userColumn = i
  }
}
# filter out rows with missing data
forClustering <- filter(dat, is.na(userVariable) == FALSE)
# plot histogram of data
histogramPlot <- ggplot(forClustering, mapping = aes_string(x = userVariable)) + geom_histogram() + theme_bw()
ggsave("Histogram.svg", plot = histogramPlot, device = "svg",  width = 7, height = 5.5, units = "in")

################
## CLUSTERING ##
################
# create sequence of clusters to fit
k <- seq(1,clusterMax)
# cluster data with kmeans, using the range of centroids specified by the k vector and rerunning each cluster 50 times with different random starting point(s)
res <- lapply(k, function(i){kmeans(forClustering[userColumn], i, nstart=50)})
# get the total within-cluster sum of squares for each cluster number
tot_withinss <- sapply(k, function(i){res[[i]]$tot.withinss})
# make tibble of cluster size and average silhouette coefficient
clusterStats <- tibble(x = k, y = tot_withinss)
names(clusterStats) <- c("ClusterSize", "TotalWithinSS")
# plot goodness-of-fit for each number of clusters
fitPlot <- ggplot(clusterStats, mapping = aes(x = ClusterSize, y = TotalWithinSS)) +
  geom_point(size = 3) +
  geom_line(size = 1) +
  theme_bw() +
  xlab("Number of clusters (k)") + 
  ylab("Within-cluster total sum of squares") +
  scale_x_continuous(breaks=k[2:length(k)], labels=k[2:length(k)]) + 
  theme(panel.grid.minor.x = element_blank())
#fitPlot
ggsave("Fit.svg", plot = fitPlot, device = "svg",  width = 7, height = 5.5, units = "in")

########################
## CLUSTER EVALUATION ##
########################
# define a new k starting at 2 and finishing at the same position
newk <- seq(2,k[length(k)])
# cluster data with new kmeans, using the range of centroids specified by the k vector and rerunning each cluster 50 times with different random starting point(s)
newRes <- res[2:length(res)]
# calculate the euclidean distance matrix
distances <- dist(forClustering[userColumn])
# to evaluate the best-fitting model, calculate the silhouette coefficient for each data point according to each cluster number
silhouettes <- lapply(newk, function(i){silhouette(newRes[[i-1]]$cluster, distances)})
# calculate the mean silhouette coefficient for each cluster number (skipping k=1)
meanSilhouette <- sapply(silhouettes, function(x){mean(x[,3])})
# add average silhouette coefficient to cluster statistics tibble (NB: first entry is NA as there isnt a silhouette coefficient for k=1)
clusterStats$Silhouette <- c(NA, meanSilhouette)
# bar chart of average silhouette coefficients
meanSilhouettePlot <- ggplot(clusterStats, mapping = aes(x = ClusterSize, y = Silhouette)) +
  geom_bar(stat = "identity") +
  theme_bw() +
  xlab("Number of clusters (k)") + 
  ylab("Mean silhouette coefficient") +
  scale_x_continuous(breaks=newk, labels=newk) + 
  theme(panel.grid.minor.x = element_blank())
#meanSilhouettePlot
ggsave("MeanSilhouette.svg", plot = meanSilhouettePlot, device = "svg",  width = 7, height = 5.5, units = "in")

###############################################
## CLUSTER DATA USING OPTIMUM CLUSTER NUMBER ##
###############################################
# remove k=1 row and sort silhouette coefficient in descending order
clusterStatsOrdered <- clusterStats %>% filter(k > 1) %>% arrange(desc(Silhouette))
# extract the value of k corresponding to the highest silhouette coefficient
optimumK <- as.integer(clusterStatsOrdered[1,1])
# assign the cluster assignments for each element based on the optimum cluster number
forClustering$Cluster <- as.vector(newRes[[optimumK]]$cluster)
# plot silhouette for optimum k
optimumSilhouette <- silhouette(newRes[[optimumK-1]]$cluster, distances)
kColours <- brewer.pal(length(newk), "Set1")
svg(filename = "OptimumSilhouette.svg", width = 7, height = 5.5)
plot(optimumSilhouette, border=NA, col=kColours[sort(newRes[[optimumK-1]]$cluster)], main="")
dev.off()

