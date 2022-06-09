library(future)
library(future.apply)
library(DBI)
library(RSQLite)
library(tidyverse)


plan(multicore, workers = 8)

conn <- dbConnect(RSQLite::SQLite(), "./natenews.sqlite")

# 2015년부터 향후 7년 간 주 간격으로 시간 샘플링.
seq(
    as.Date("2015/01/01"),
    by = "week",
    length.out = (365 * 7 + 2) / 7
) -> ds

# tor proxy를 이용.
httr::set_config(httr::use_proxy("socks5://localhost:9050"))

df <- do.call(rbind, future_Map(function(date) {
    data.frame(
        year = as.integer(format(date, "%Y")),
        month = as.integer(format(date, "%m")),
        week = as.integer(format(date, "%U")),
        get_news_list(format(date, "%Y%m%d"), F)
    )
}, ds))

dbWriteTable(conn, "week_articles", df, append = TRUE)

