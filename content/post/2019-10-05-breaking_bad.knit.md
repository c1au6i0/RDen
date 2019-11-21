---
title: 'Breaking Bad: Yeah Science, b#@ch!'
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
**How many times was the word “bitch” said in Breaking Bad?** Aaron Paul thinks that he used the word at least one hundred times, whereas, according to [Kerplosh]( https://www.youtube.com/watch?v=WVR476WHmR8), the number is actually 54.  Was it pronounced that often? We can answer this question using *R*.
<!--more-->

We don’t need to watch the entire show again: **with the subtitles and some coding we can get to the bottom of this much quicker**. I wrote a function to import and make the subtitles tidy, few lines of code to tokenize the dialogue, and I got all the words pronounced in Breaking Bad (code is at the end of the post).













