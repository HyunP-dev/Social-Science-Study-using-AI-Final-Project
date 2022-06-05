library(reticulate)
use_python("~/anaconda3/bin/python")

source("./natenews.r")

library(future)
library(future.apply)

library(tidyverse)

text_classify <- import("model")$text_classify

plan(multicore, workers = 8)


# 이걸 쓰자!
seq(
    as.Date("2015/01/01"),
    by = "week",
    length.out = (365 * 7 + 2) / 7) -> ds

# 이건 데이터셋이 너무 많아져서 쬬큼...
seq(
    as.Date("2015/01/01"),
    by = "day",
    length.out = 10) -> ds

tasks <- future_Map(function(date) {
    cbind(
        year = as.integer(format(date, "%Y")),
        month = as.integer(format(date, "%m")),
        week = as.integer(format(date, "%U")),
        get_news_list(format(date, "%Y%m%d"), F))
}, ds)

do.call(rbind, tasks) -> df
