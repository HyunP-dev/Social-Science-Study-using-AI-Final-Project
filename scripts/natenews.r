library(rvest)
library(magrittr)
library(stringr)

get_news_list <- function(date, week) {
    parameter <- sprintf("sc=&p=%s&date=%s", ifelse(week, "week", "day"), date)
    url <- paste("https://news.nate.com/rank/cmt", parameter, sep = "?")
    doc <- rvest::read_html(url)
    tail <- doc |> rvest::html_elements(".mduSubject > *")
    head <- doc |> rvest::html_elements(".mduSubjectList")
    extract_tail_element <- function(e) {
        a <- rvest::html_element(e, "a")
        ems <- rvest::html_elements(e, "em")
        list(
            rank = as.integer(rvest::html_text(ems[1])),
            comment =
                rvest::html_text(ems[2]) |>
                    stringr::str_remove_all(",") |>
                    as.integer(),
            title = rvest::html_text(a),
            url = paste0("https:", rvest::html_attr(a, "href"))
        )
    }
    extract_head_element <- function(e) {
        ems <- rvest::html_elements(e, "em")
        a <- rvest::html_element(e, "a")
        list(
            rank = as.integer(rvest::html_text(ems[1])),
            comment =
                rvest::html_text(ems[2]) |>
                    stringr::str_remove_all(",") |>
                    as.integer(),
            title =
                rvest::html_element(a, "strong") |>
                    rvest::html_text(),
            url = paste0("https:", rvest::html_attr(a, "href"))
        )
    }
    tail <- Map(extract_tail_element, tail)
    head <- Map(extract_head_element, head)
    do.call(rbind.data.frame, append(head, tail))
}

get_news_comments <- function(url, page) {
    artc_sq <- urltools::url_parse(url)$path |> substring(6)
    mid <- urltools::param_get(url, "mid")[[1]]
    comment_url <- paste0(
        "https://comm.news.nate.com/Comment/ArticleComment/List?",
        "artc_sq=%s&",
        "order=&cmtr_fl=0&prebest=0&clean_idx=&user_nm=&fold=&",
        "mid=%s&domain=&argList=0&best=0&return_sq=&connectAuth=N&page=%d"
    ) |>
        sprintf(artc_sq, mid, page)
    doc <- rvest::read_html(comment_url)
    cmt_items <- doc |> rvest::html_elements(".cmt_item")
    do.call(rbind.data.frame, Map(function(item) {
        list(
            name = item |>
                rvest::html_element(".nameui") |>
                rvest::html_text() |>
                stringr::str_trim(),
            date = item |>
                rvest::html_element(".date") |>
                rvest::html_text() |>
                substring(3) |>
                paste(substring(artc_sq, 1, 4)),
            text = item |>
                rvest::html_element(".usertxt") |>
                rvest::html_text() |>
                stringr::str_trim()
        )
    }, cmt_items))
}