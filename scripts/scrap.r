library(future)
library(future.apply)
library(DBI)
library(RSQLite)
library(tidyverse)


source("./scripts/natenews.r")

plan(multicore, workers = 8)

conn <- dbConnect(RSQLite::SQLite(), "./databases/natenews.sqlite")


# [ 댓글을 수집할 기사들의 url 수집 ]

# 2015년부터 향후 7년 간 주 간격으로 시간 샘플링.
seq(
    as.Date("2015/01/01"),
    by = "week",
    length.out = (365 * 7 + 2) / 7
) -> ds

# tor proxy를 이용.
# 포트 확인:
#   sudo netstat -nap | grep LISTEN | grep tor
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


# [ 댓글 수집 ]

curr <- dbGetQuery(conn, "SELECT url FROM scraped_urls")
targets <- Filter(function(url) which(curr$url == url) == 0, df$url)
pb <- progress_bar$new(total = length(targets))
for (url in targets) {
    do.call(
        rbind.data.frame,
        future_Map(function(page) {
            tryCatch(
                expr = get_news_comments(url, page),
                error = function(e) data.frame()
            )
        }, 1:5)
    ) -> comments_df
    if (nrow(comments_df) == 0) next
    dbWriteTable(conn, "comments",
        cbind(url = url, comments_df),
        append = TRUE
    )
    pb$tick()
}
