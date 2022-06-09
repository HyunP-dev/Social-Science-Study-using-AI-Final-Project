library(reticulate)
use_python("~/anaconda3/bin/python")

source("./natenews.r")

library(future)
library(future.apply)

library(tidyverse)

text_classify <- import("model")$text_classify

plan(multicore, workers = 8)

httr::set_config(httr::use_proxy("socks5://localhost:9050"))
httr::reset_config()



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

comments_df$text |>
    text_classify() -> cfd_df
cfd_df |>
    sapply(mean) |>
    barplot()


library(DBI)
library(RSQLite)
conn <- dbConnect(RSQLite::SQLite(), "./natenews.sqlite")




dbGetQuery(conn, "SELECT * FROM comments") |> View()
