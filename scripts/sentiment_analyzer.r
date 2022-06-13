library(httr)
library(stringi)
library(rjson)

text_classify <- function(texts) {
    res <- POST(
        "127.17.0.2:80/classify",
        body = as.list(texts),
        encode = "json"
    )
    content(res, "text") |>
        stri_unescape_unicode() |>
        fromJSON() |>
        as.data.frame()
}