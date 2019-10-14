---
title: 'Breaking Bad: Yeah Science, bitch!'
author: 'C1au6i0_HH'
date: '2019-10-14'
slug: breaking_bad
categories: 
  - R
lastmod: '2019-10-05T12:42:13-04:00'
tags:
  - R
  - wordcloud
  - ggplot
  - textmining
comment: yes
toc: yes
autoCollapseToc: yes
contentCopyright: yes
reward: no
mathjax: no
---
**How many times was the word “bitch” said in Breaking Bad?** Aaron Paul thinks that he used the word at least one hundred time, whereas, according to [Kerplosh]( https://www.youtube.com/watch?v=WVR476WHmR8), the number is actually 54.  Was it pronounced that often? We can answer this question using *R*.
<!--more-->

We don’t need to watch the entire show again: **with the subtitles and some coding we can get to the bottom of this much quicker**. I wrote a function to import and make the subtitles tidy, few lines of code to tokenize the dialogue, and I got all the words pronounced in Breaking Bad (code is at the end of the post).



# Some bulk numbers

The words "bitch" and "bitches" were pronounced a total of **108 times** (96 and 12 times, respectively) by Jessy and the other characters of Breaking Bad. Among the ~9952 unique words, “bitch” was the 165th most used.
While this is not an insignificant use of the colorful locution, **it is far below the top 7 words**, which are pronounced 9 to 16-fold more frequently than “bitch”.


|words   |frequency |position |
|:-------|:---------|:--------|
|just    |1676      |1        |
|know    |1669      |2        |
|right   |1428      |3        |
|yeah    |1147      |4        |
|like    |1114      |5        |
|get     |960       |6        |
|okay    |924       |7        |
|...     |...       |...      |
|bitch   |96        |165      |
|bitches |12        |1054     |

Was it at least the most used among swear words?


|words   | frequency|
|:-------|---------:|
|shit    |       134|
|damn    |       120|
|bitch   |        96|
|asshole |        33|
|crap    |        32|

Surprisingly… no! The word “shit” and “damn” were used slightly more than "bitch".

# By season and episode

They started slow... The graph bellow shows the number of occurrences per season. 

<center> 
*[click on the figure to enlarge it]* 
</center>

<img src="/post/2019-10-05-breaking_bad_files/figure-html/bitch_season-1.png" width="672" />

In the first season, the words “bitch” and “bitches” were used only 10 times. The seasons with the highest number of uses of those words was the second (28) and the third (27). After a slight decrease in the fourth season (18), the frequency went up again in the last season (25).

Seasons had a different number of episodes and the use of the expression was not normally distributed. For these reasons it is worth to take a look at each single episode.

<center> 
*[click on the figure to enlarge it]* 
</center>

<img src="/post/2019-10-05-breaking_bad_files/figure-html/unnamed-chunk-1-1.png" width="672" />

The maximal number of occurrences per episode were 7 and 6 in Season 3 – Episode 10 and Season 3 -Episode 6, respectively. Season 2 and Season 3 averaged about 2, whereas the other 1 to 1.5 occurrence of the word per episode.

# Wordcloud

I don’t have an obsession for swear words so…here a wordcloud of **all** the words of the show!

<center> 
*[click on the words to check their frequency]* 
</center>

<iframe seamless src="/data/data_post7/bb.html" width="100%" height="400" frameBorder="0"></iframe>


# Conclusions

* The word "bitch" (and "bitches") was pronounced a total of **108 times**, and it was not the most common swear word in the show. 
* The number of uses peaked in Season 2 with a total of 28 occurrences.
* The episode 6 of Season 2 was the one in which the word whose used the most (7 times).

# CODE


```r
library(tidytext)
library(tidyverse)
library(data.table)
library(lubridate)
library(vroom)
library(svDialogs)
library(stringr)
library(wordcloud2)
library(htmlwidgets)
library(widgetframe)

# function to import subtitles that are locate all in a folder
import_sub <- function(link_file){
  
  #extract season and episode from file name
  info_ser <- str_split(str_extract(link_file, "[:digit:]+x[:digit:]+"), "x", simplify = TRUE)

  subt <- vroom_lines(link_file)
  # last 3 rows are specifications for fonts and colors
  subt <- subt[1:(length(subt)-3)]
  
  # extract number (order) of  subtitles and positions
  arg <- list(subt, "^[:digit:]+$")
  numb_pos <- map(list(str_subset, str_which), exec, !!!arg)
  
  # this create a col where numbers are repeated
  subt <- bind_cols(numb = as.numeric(rep(numb_pos[[1]], 
               diff(
                 c(numb_pos[[2]], length(subt)+1)
                 ))),
               X1 = subt)
  
  subt2 <- subt %>% 
      mutate(what = 
               case_when(
                  str_detect(X1, "[:digit:]+:[:digit:]+") ~ "time_sub",
                  str_detect(X1, "[:alpha:]") ~ "dial")
             ) %>% 
      na.omit() %>% 
      group_by(numb, what) %>% 
      summarize(X1 = paste(X1, collapse = " ")) %>% 
      pivot_wider(names_from = what, values_from = X1)  %>% 
      separate(time_sub, c("start_t", "end_t"), sep = " --> ")  %>% 
      mutate(season = as.numeric(info_ser[[1]]),
             episode = as.numeric(info_ser[[2]]))  %>% 
      mutate_at(c("start_t", "end_t"), as.POSIXct, format = "%H:%M:%OS") %>% 
      ungroup()
  
  # shorturl.at/cpRU2
  message(paste0("File ", link_file, " imported!"))
  return(subt2)
}

# folder and files
subt_folder <- "/Users/heverz/Documents/R_projects/RDen/static/data/data_post7/breaking bad"
list_files <- list.files(subt_folder, full.names = TRUE)

# import - bb stands for breaking bad
bb <- map_dfr(list_files, import_sub)

bb <- bb %>% 
   mutate(dial = str_remove_all(dial, pattern = "(\\[.*?\\])|(<.*>)|(Sync and.*)")) 

# tokenize
stop_words <- get_stopwords(language = "en")
bb_words <- bb %>% 
   unnest_tokens(input = dial, output = "words", token = "words", format = "text")  %>% 
   filter(str_detect(words, "[[:alpha:]]"),
          !words %in% stop_words$word)

# table1 - bitch
tab <- bb_words %>%
  group_by(words) %>% 
  summarize(frequency = n()) %>% 
  arrange(desc(frequency)) %>% 
  mutate(position = seq_along(words)) %>% 
  filter(position %in% 1:7 | words %in% c("bitch", "bitches"))
  
tab1 <- 
  do.call("rbind", list(tab[1:7,], rep("...", 3), tab[8:9,])) %>% 
  as.data.frame()

# table2 - swear words
tab2 <- bb_words %>% 
  filter(str_detect(words, "^bitch*") | words %in% c("shit", "fuck", "damn", "asshole", "assholes", "slut", "whore", "goddamn", "cunt", "crap", "prick")) %>% 
  group_by(words) %>% 
  summarize(frequency = n()) %>% 
  arrange(desc(frequency)) %>% 
  head(5)

# graph1 - by season

graph1 <- bb_words %>% 
  filter(str_detect(words, "^bitch*")) %>%
  mutate(season = paste("Season ", season)) %>% 
  group_by(season) %>% 
  summarize(n = n()) %>% 
  
  ggplot(aes(x = season, y = n, group = season, fill = as.factor(season))) + 
    geom_col(colour = "black", size = 0.3) +
    scale_fill_brewer(palette="Dark2") +
    scale_y_continuous(breaks = seq(0,30, 5), limits = c(0, 30)) +
    labs(x = NULL,
         y = "number of times used", 
         title =  expression("Words" ~italic("BITCH + BITCHES"))) +
    geom_text(aes(y = n - 2,
                 label = n),
                  size = 4) +
    theme(plot.title = element_text(hjust = 0.5, size = 15, face = "bold"),
          axis.text.x  = element_text(hjust = 0.5, size = 10, face = "bold"),
          legend.position = "none")
# averages of season by episode
bb_words %>% 
  filter(str_detect(words, "^bitch*")) %>%
  mutate(season = paste("Season ", season)) %>% 
  group_by(season) %>% 
  summarize(n = n()) %>% 
  arrange(season) %>% 
  mutate(episode_n = c(7, 13, 13, 13, 16), mean_episode = n/episode_n)

# graph2 - episodes
graph2 <- bb_words %>% 
  filter(str_detect(words, "^bitch*")) %>% 
  mutate(season = paste("Season ", season)) %>% 
  group_by(season, episode) %>% 
  summarize(n = n()) %>%
  # ggplot(aes( n)) +
  #   geom_histogram(binwidth = 1)
  
  ggplot(aes(x = episode, y = n,  fill = as.factor(season))) + 
    geom_col(position = "dodge2", colour = "black", size = 0.3) +
    scale_fill_brewer(palette="Dark2") +
    facet_grid(season ~ .) +
        labs(x = "episode",
         y = "number of time used", 
         title = expression("Words:"~italic("BITCH + BITCHES"))) +
    scale_x_continuous(breaks = seq(1,16, 1), limits = c(0.5, 16.5)) +
    geom_text(aes(y = 0.6,
                 label = n),
                  size = 3) +
    theme(plot.title = element_text(hjust = 0.5, size = 15, face = "bold"),
          axis.title.x = element_text(hjust = 0.5, size = 10, face = "bold"),
          legend.position = "none")

# wordcloud
bb_wordcloud <-
  bb_words %>%
  group_by(words) %>% 
  summarize(freq = n()) %>% 
  wordcloud2::wordcloud2(shape = "circle")
```


