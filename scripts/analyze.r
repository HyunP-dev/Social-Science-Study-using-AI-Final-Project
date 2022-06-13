library(future)
library(future.apply)
library(DBI)
library(RSQLite)
library(tidyverse)
library(progressr)
library(plotly)
library(sqldf)
library(NbClust)
library(factoextra)
library(RmecabKo)

source("./scripts/sentiment_analyzer.r")


plan(multicore, workers = 8)
conn <- dbConnect(RSQLite::SQLite(), "./databases/natenews.sqlite")

df <- dbGetQuery(conn, "SELECT * FROM comments") |>
    mutate(date = strptime(date, "%m.%d %H:%M %Y")) |>
    select(date, text)

with_progress({
    pb <- progressor(steps = nrow(df))
    do.call(rbind, future_Map(
        function(text) {
            res <- cbind(
                text = text,
                text_classify(text)) |>
                    tryCatch(error = function(e) data.frame())
            pb()
            return(res)
        }, df$text)) -> classified_df
})

dbCreateTable(conn, "classified_texts", classified_df)
dbWriteTable(conn, "classified_texts", classified_df, append = T)
dbGetQuery(conn, "SELECT * FROM comments") -> comments

dbGetQuery(conn, "
SELECT
    DISTINCT (name || date || comments.text) as uniquecol,
    date,
    ct.*
FROM comments
INNER JOIN classified_texts ct
ON comments.text = ct.text") |>
    mutate(ym = paste(
        substring(date, 13, 16),
        substring(date, 1, 2))) |>
    mutate(year = as.integer(substring(date, 13, 16))) |>
    select(!uniquecol) -> joined_df

joined_df |>
    group_by(ym) |>
    summarise(
        clean = mean(clean),
        기타.혐오 = mean(기타.혐오),
        남성 = mean(남성),
        성소수자 = mean(성소수자),
        악플.욕설 = mean(악플.욕설),
        여성.가족 = mean(여성.가족),
        연령 = mean(연령),
        인종.국적 = mean(연령),
        종교 = mean(종교),
        지역 = mean(지역)) -> analyzed_df


data.frame(word = future_Map(
    nouns,
    sqldf("
SELECT text FROM joined_df
WHERE ym LIKE'2015 __'")$text) |>
    unlist() |>
    as.vector()) -> words_df
sqldf("
SELECT
    word,
    COUNT(1) as count
FROM words_df
GROUP By word
HAVING length(word) > 2
   AND count > 50
") |> wordcloud2(rotateRatio = 0)

analyzed_df |>
    select(-ym) |>
    kmeans(centers = 2) |>
    fviz_cluster(data = analyzed_df |> select(-ym)) |>
    ggplotly()

plot_ly(analyzed_df, x = ~ym) |>
    add_trace(y = ~clean, type = "scatter", mode = "lines", name = "clean") |>
    add_trace(y = ~기타.혐오, type = "scatter", mode = "lines", name = "기타.혐오") |>
    add_trace(y = ~남성, type = "scatter", mode = "lines", name = "남성") |>
    add_trace(y = ~성소수자, type = "scatter", mode = "lines", name = "성소수자") |>
    add_trace(y = ~악플.욕설, type = "scatter", mode = "lines", name = "악플.욕설") |>
    add_trace(y = ~여성.가족, type = "scatter", mode = "lines", name = "여성.가족") |>
    add_trace(y = ~연령, type = "scatter", mode = "lines", name = "연령") |>
    add_trace(y = ~인종.국적, type = "scatter", mode = "lines", name = "인종.국적") |>
    add_trace(y = ~종교, type = "scatter", mode = "lines", name = "종교") |>
    add_trace(y = ~지역, type = "scatter", mode = "lines", name = "지역") |>
    layout(
        xaxis = list(title = "YYYY MM"),
        yaxis = list(title = "혐오지수")
    ) -> fig
fig
orca(fig, "reports/images/lineplot.pdf", format = "pdf")

Reduce(function(acc, cur) {
        acc %>%
            add_trace(
                r = as.vector(unlist(cur))[2:11],
                theta = attributes(cur)$names[2:11],
                name = unlist(cur)[1]
            )
    }, analyzed_df |> transpose(), plot_ly(
        type = "scatterpolar",
        fill = "toself"
    )) -> fig
fig
orca(fig, "reports/images/radarchart.pdf", format = "pdf")

