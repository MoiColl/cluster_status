# Cluster Status

Plot an interactive graph to check the GenomDK queue status.

This repository contains two files which you will need to plot statistics about the jobs in the queue system of the GenomDK cluster. The first script `cluster_status.sh` is a bash command that you need to run to generate the dataframe with all the information to be plotted. You can copy&paste the command directly to the terminal and run it on the cluster, or you can simply run it as a script 

```
$ bash cluster_status.sh
```

Then, you can use the output `cluster_status.txt` file, and plot the information in R with the script `cluster_status.R`. 

At the header of the R script you will see that you need to install:
  - `tidyverse`
  - `cowplot`
  - `ggiraph` 
  
and that there are two variables that you should modify: 
  - `path_cluster_status` : self explanatory.
  - `color_users` : you can use to color specific users (on the plot below, I colored 3 users in blue, green and red).
  
Once you run the R script, you will obtain a plot like the one below:


![plot](https://user-images.githubusercontent.com/18718522/217531453-ddbef956-ae63-4ee9-893d-065946227e25.png)

The facets shown in the plot are:

- On columns:
  The jobs are stratified depending on their "status": pending (waiting to run), dpending (they depend on other jobs to run) and running. 
- On rows:
  - MEM : memory requested [Gb]
  - PRIORITY : priority value (hihger values mean higher priority) [no unit]
  - TIME : time running; that is why depending and pending jobs have values of 0 [Hours]
  - TIME_LIMIT : time requested [Hours]
  - TIME_PERCENTAGE : Percentage of the requested time that the job has been running (TIME*100/TIME_LIMIT) [%]
  - WAITING : time that have been waiting to be run [hours]
  - NUM_JOBS : Number of jobs in that status 
  
Hope you can use it and have fun bitching about the user with trilion jobs colapsing the cluster!


