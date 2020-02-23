---
title: "Interactive Maps in R: Maryland Vehicle Crashes"
author: c1au61o_HH
date: '2020-02-11'
slug: interactive-maps
categories:
  - R
tags: 
  - maps
  - leaflet
  - Maryland
  - crashes
lastmod: "2020-02-23 12:29:09"
keywords: []
description: ''
comment: yes
toc: no
autoCollapseToc: no
contentCopyright: no
reward: no
mathjax: no
---

Creating interactive maps might seems a pretty complex task, that would require deep knowledge of `JavaScript` and quite some coding. Luckily, the package `leaflet` allows `R` users of taking advantage of the homonym `JavaScript` library **to create interactive maps** in just 3 lines of code. Let's look at the vehicle crashes in Maryland in 2019 with an interactive map!

<!--more-->

# The Data

Data on Maryland vehicle crashes can  be downloaded from the open data portal of the state ((link)[https://opendata.maryland.gov/Public-Safety/Maryland-Statewide-Vehicle-Crashes/65du-s3qu]).
Let's load some libraries, import the data and extract crashes of 2019.


```r
library(leaflet)
library(tidyverse)

c_dat <- read.csv("path_to_csv", na.strings=c(""," ","NA")) %>%
  janitor::clean_names()

md <- c_dat %>% 
  filter(year == 2019)
```



# Interactive Map

We select the `latitude` and `longitude` columns, we feed them to `leaflet`and... with just 3 lines of code we build an interactive map!


```r
md %>%
  select(latitude, longitude) %>%

  leaflet() %>%                                         # fist line
  addTiles() %>%                                        # second line
  addCircleMarkers(radius = 2, clusterOptions = "yes")  # third line
```


<iframe title="Prison_video" height="400" src="/data/data_crashes/md.html" frameBorder="0" allowfullscreen></iframe>

...Done!!!

Check out [rstudio tutorial](https://rstudio.github.io/leaflet/) for other info on `leaflet` and...drive safe!





