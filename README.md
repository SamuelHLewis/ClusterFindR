# ClusterFindR
## Purpose
Finds clusters in continuous data, by using a partitioning algorithm (kmeans).
## Requirements
Written in R.

Requires the following R packages:

[argparse](https://cran.r-project.org/web/packages/argparse/index.html)

[tidyverse](https://cran.r-project.org/web/packages/tidyverse/index.html)

[cluster](https://cran.r-project.org/web/packages/cluster/index.html)

# Usage
Basic usage is:
```bash
ClusterFindR.R --input="TestDistributions.csv" --variable="Bimodal" --clusters=2
```
ClusterFindR takes 3 mandatory arguments:

	--input (input data table in csv format - must have column headers)

	--variable (variable to use to cluster data - must uniquely match a column header in the input)

	--clusters (maximum number of clusters - ClusterFindR tries to fit each value of k from 1 to this number)

# ModalDistributor
## Purpose
Generates a sample from a distribution with a given number of modes. Designed to produce test data for ClusterFindR.
## Requirements
Written in R.

Requires the following R packages:

[argparse](https://cran.r-project.org/web/packages/argparse/index.html)

# Usage
Basic usage is:
```bash
ModalDistributor.R --sampleSize=1000 --mean=1 --standardDeviation=1 --modes=1 --interval=10
```
This will print a column of 1000 numbers to the file "Distributions.txt".

