#!/usr/bin/env Rscript

# this code is adapted from the University of Cambridge Introduction to Machine Learning course (https://github.com/bioinformatics-training/intro-machine-learning-2017/blob/master/09-clustering.Rmd)

suppressPackageStartupMessages(library("argparse"))
suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("cluster"))
suppressPackageStartupMessages(library("gridExtra"))
suppressPackageStartupMessages(library("grid"))
suppressPackageStartupMessages(library("lattice"))

#########################
# user argument parsing #
#########################
# create parser object
parser <- ArgumentParser()
# parse input table
parser$add_argument("-i", "--input", type = "character", help = "Input data table (must be in tab-separated text format with a header, and missing data must be marked with \".\")")
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

## hard-coded user options (for testing)
#userInput <- "TestDistributions.tsv"
#userVariable <- "Trimodal"
#clusterMax <- 9

# read in data
dat <- read_tsv(userInput, na = ".")
# find column number in input data that corresponds to the user variable (because this has to be used to call the data from this column later on, rather than using the column name)
for (i in seq(1:length(names(dat)))){
  if (names(dat)[i] == userVariable){
    userColumn = i
  }
}
# filter out rows with missing data
forClustering <- filter(dat, is.na(dat[userColumn]) == FALSE)
# plot histogram of data
histogramPlot <- ggplot(forClustering, mapping = aes_string(x = userVariable)) +
  geom_histogram() +
  ggtitle(paste("Distribution of ",userVariable)) +
  xlab("") +
  ylab("Count") +
  theme_bw()

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
  ggtitle("Fit of each number of clusters") +
  xlab("Number of clusters (k)") + 
  ylab("Within-cluster total sum of squares") +
  scale_x_continuous(breaks=k[2:length(k)], labels=k[2:length(k)]) + 
  theme(panel.grid.minor.x = element_blank())

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
  ggtitle("Quality of each number of clusters") +
  xlab("Number of clusters (k)") + 
  ylab("Mean silhouette coefficient") +
  scale_x_continuous(breaks=newk, labels=newk) + 
  theme(panel.grid.minor.x = element_blank())

###############################################
## CLUSTER DATA USING OPTIMUM CLUSTER NUMBER ##
###############################################
# remove k=1 row and sort silhouette coefficient in descending order
clusterStatsOrdered <- clusterStats %>% filter(k > 1) %>% arrange(desc(Silhouette))
# extract the value of k corresponding to the highest silhouette coefficient
optimumK <- as.integer(clusterStatsOrdered[1,1])
# assign the cluster assignments for each element based on the optimum cluster number
forClustering$Cluster <- as.vector(newRes[[optimumK-1]]$cluster)
# extract silhouette for optimum k
optimumSilhouette <- silhouette(newRes[[optimumK-1]]$cluster, distances)
# create new tibble for optimumSilhouette
optimumSilhouetteTibble <- tibble(optimumSilhouette[,1], optimumSilhouette[,2], optimumSilhouette[,3])
names(optimumSilhouetteTibble) <- c("Cluster", "Neighbour", "SilhouetteWidth")
# order each cluster by silhouette width in descending order & add a column of position of each point in ordered table to plot by
optimumSilhouetteTibblePlottable <- optimumSilhouetteTibble %>% group_by(Cluster) %>% arrange(SilhouetteWidth) %>% mutate(PlottingIndex = row_number(Cluster))
# plot silhouette profile
optimumSilhouettePlot <- ggplot(optimumSilhouetteTibblePlottable, mapping = aes(x = PlottingIndex, y = SilhouetteWidth)) +
  geom_bar(stat = "identity", aes(fill = as.factor(Cluster))) +
  theme_bw() +
  facet_wrap(~Cluster, ncol = 1, strip.position = "left") +
  coord_flip() +
  ggtitle("Silhouette profile of optimum k") +
  xlab("Cluster") +
  ylab("Silhouette width") +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    strip.background = element_blank(),
    panel.border = element_blank(),
    legend.position = "none",
    strip.text.y = element_text(angle = 180),
    axis.ticks.y = element_blank(),
    axis.text.y = element_blank()
  )

############
## OUTPUT ##
############
# output data with cluster assignments (NB: any row with NA in column used for clustering will be removed)
write.table(forClustering, file = "Clustered.tsv", row.names = FALSE)
# build and write summary plot
summaryPlot <- grid.arrange(histogramPlot, fitPlot, meanSilhouettePlot, optimumSilhouettePlot, ncol = 2)
ggsave("summaryPlot.pdf", plot = summaryPlot, device = "pdf",  width = 8.3, height = 11.7, units = "in")
