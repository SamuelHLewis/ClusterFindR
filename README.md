# ClusterFindR
## Purpose
Finds clusters in continuous data, by using a partitioning algorithm (kmeans).
## Requirements
Written in R.

Requires the following R packages:

[argparse](https://CRAN.R-project.org/package=argparse)

[tidyverse](https://CRAN.R-project.org/package=tidyverse)

[cluster](https://CRAN.R-project.org/package=cluster)

[gridExtra](https://cran.r-project.org/package=gridExtra)

[grid](https://www.rdocumentation.org/packages/grid/versions/3.4.3)

[lattice](https://cran.r-project.org/package=lattice)

## Usage
Basic usage is:
```bash
ClusterFindR.R --input="TestDistributions.tsv" --variable="Trimodal" --clusters=9
```
ClusterFindR takes 3 mandatory arguments:

	--input (input data table in tsv format - must have column headers)

	--variable (variable to use to cluster data - must uniquely match a column header in the input)

	--clusters (maximum number of clusters - ClusterFindR tries to fit each value of k from 1 to this number)

## Output
ClusterFindR writes a `Clustered.tsv` file to the working directory. This is the same as the input file, but with an additional "Cluster" column added denoting which cluster each observation belongs to according to the optimum cluster number. ClusterFindR also outputs a summary figure `summaryPlot.pdf`. This visualizes the distribution of the variable used for clustering, the fit and quality of of each value of k, and the silhouette profile for the optimum k. 
![](https://raw.githubusercontent.com/SamuelHLewis/ClusterFindR/master/ExampleOutput.jpg)

## References
This code is adapted from the University of Cambridge [Introduction to Machine Learning course](https://github.com/bioinformatics-training/intro-machine-learning-2017/blob/master/09-clustering.Rmd)


# Generating test data
## ModalDistributor.R
To generate test data for ClusterFindR, the script `ModalDistributor.R` can be used. This generates a sample from a distribution with a user-defined number of modes.
## Requirements
Written in R.

Requires the following R packages:

[argparse](https://cran.r-project.org/web/packages/argparse/index.html)

## Usage
Basic usage is:
```bash
ModalDistributor.R --sampleSize=1000 --mean=1 --standardDeviation=1 --modes=1 --interval=10
```
ModalDistributor takes 5 mandatory arguments:

	--sampleSize (the number of observations)

	--mean (the mean of the first distribution)

	--standardDeviation (the standard deviation of each distribution)

	--modes (the number of modes)

	--interval (the distance between the means of each distribution)

## Output
ModalDistributor will write the observations as a column to the file `Distributions.txt` in the working directory.

