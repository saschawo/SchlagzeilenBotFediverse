library(tidyRSS)
library(stringr)
library(rtoot)

options("rtoot_token" = "SZBot.rds")
options(stringsAsFactors = F)

feed <- tidyfeed("https://rss.sueddeutsche.de/rss/Topthemen")
titles <- feed$item_title

# titles with exactly one colon
titles <- titles[str_count(titles, fixed(":")) == 1]

# titles without filtered words
stopword.pattern <- "Newsblog|SZ|ticker"
titles <- titles[grep(stopword.pattern, titles, ignore.case = F, invert = T)]

split.titles <- strsplit(titles, ":", fixed = T)

# only titles with more than one word on both sides
lens.left <- sapply(split.titles, FUN = function (x) {
  x <- str_trim(x[1])
  str_count(x, "[[:space:]]") + 1
})
lens.right <- sapply(split.titles, FUN = function (x) {
  x <- str_trim(x[2])
  str_count(x, "[[:space:]]") + 1
})
split.titles <- split.titles[lens.left > 1 & lens.right > 1]

left.parts <- str_trim(sapply(split.titles, FUN = function (x) x[1]))
right.parts <- str_trim(sapply(split.titles, FUN = function (x) x[2]))

# Check old left & right parts
used.left.parts <- scan("~/Data/SZ_left_parts.txt", what = "c", sep = "\n")
left.parts <- left.parts[!(left.parts %in% used.left.parts)]
used.right.parts <- scan("~/Data/SZ_right_parts.txt", what = "c", sep = "\n")
right.parts <- right.parts[!(right.parts %in% used.right.parts)]

originals <- paste(left.parts, right.parts, sep = ": ")
df <- expand.grid(left.parts, right.parts)
df$new <- paste(df$Var1, df$Var2, sep = ": ")

# exclude originals
df$use <- !(df$new %in% originals)

df <- df[df$use,]

toot.df <- df[sample(1:nrow(df), 1),]

toot <- sample(toot.df$new, 1)

# save used left & right parts in file
write(as.character(toot.df$Var1), "~/Data/SZ_left_parts.txt", append = T, sep = "\n")
write(as.character(toot.df$Var2), "~/Data/SZ_right_parts.txt", append = T, sep = "\n")

post_toot(toot)

