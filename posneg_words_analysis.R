#this script loads the novels by years, outputs those which correlate either positively or negatively with the passage of time
#it also provides some POS analysis and outputs the result

library(readr)
library(dplyr)
library(purrr)
library(data.table)
library(textstem)

# List all CSV files
list_of_files <- list.files(path = "years",
                            recursive = TRUE,
                            pattern = "\\.csv$",
                            full.names = TRUE)

# Define the column types
col_spec <- cols(
  word_type = col_character(),
  count = col_integer()
)

# Function to read each file with filename identifier
read_csv_with_id <- function(file) {
  read_csv(file, col_types = col_spec) %>%
    mutate(file_name = basename(file)) # Adds filename as a column
}

# Load all files into a single data_oneframe, one at a time
data <- map_dfr(list_of_files, read_csv_with_id)

#reduce file name just to year
data$file_name <- substr(data$file_name, 1, 4)

#calculate totals
totals <- data %>% group_by(file_name) %>% summarise(total = sum(count))

#create removal words of words we don't want in the data
removal_words <- readLines("removal_words.txt")

#filter them out
data <- data[!data$word_type %in% removal_words,]

replacement_words <- read.csv("replacement_words.csv")

#replace some fs with esses
data$word_type <- gsub("ſ", "s", data$word_type)
data$word_type <- gsub("ﬁ", "fi", data$word_type)

data$word_type <- plyr::mapvalues(data$word_type, replacement_words$id1, replacement_words$id2, warn_missing = T)

data <- as.data.table(data)

totals <- data[, .(total = sum(count)), by = file_name]
data <- merge(data, totals, by = "file_name")
data[, relative_frequency := (count / total) * 100]

data <- data[, .(relative_frequency = sum(relative_frequency)), by = .(file_name, word_type)]

# Rank and select top 10,000 words by year
data <- data[, yearly_rank := frank(-relative_frequency, ties.method = "dense"), by = file_name]
df_top_words <- data[yearly_rank <= 10000]

# Summarize and select globally top 10,000 words
df_summary <- df_top_words[, .(total_rel_freq = sum(relative_frequency)), by = word_type]
top_10000_words <- df_summary[order(-total_rel_freq)][1:10000]

write_lines(top_10000_words$word_type, "mfws.txt")

#remove all but the top 10000 MFWs from data
data <- data %>% 
    filter(word_type %in% top_10000_words$word_type)

#drop the columns we don't need 
data <- data %>% select(file_name, word_type, relative_frequency)

#as a tibble
data <- as_tibble(data)

#pivot
data <- data %>% tidyr::pivot_wider(values_from = relative_frequency, names_from = word_type, values_fill = 0)

#normalise
data[,2:dim(data)[2]] <- scale(data[,2:dim(data)[2]])

write.csv(data, "year_data.csv")

#make numeric
data$file_name <- as.numeric(data$file_name)

#correlation object
cor_data <- as.data.frame(as.table(cor(data)))

#extract the entities which correlate with year
cor_data <- cor_data %>% filter(Var2 == "file_name")

#remove every instance which doesn't positively or negatively correlate significantly
pos <- cor_data %>% filter(Freq >= 0.7)
neg <- cor_data %>% filter(Freq <= -0.7)

#write these words to the workspace
writeLines(as.character(pos$Var1), "pos.txt")
writeLines(as.character(neg$Var1), "neg.txt")

#change columnnames
colnames(pos)[1] <- "word"
colnames(neg)[1] <- "word"

#convert these columns to characters
pos$word <- lemmatize_words(as.character(pos$word))
neg$word <- lemmatize_words(as.character(neg$word))

pos <- pos %>% distinct(word)
neg <- neg %>% distinct(word)

#remove the ones we don't need
pos$Var2 <- NULL
pos$Freq <- NULL
neg$Var2 <- NULL
neg$Freq <- NULL

#left join with pos tags
pos_pos <- as_tibble(left_join(pos, parts_of_speech))
neg_pos <- as_tibble(left_join(neg, parts_of_speech))

#create a dataframe which can tell us which  of these are more or less reliable
pos_certainty <- data.frame(
  pos = c("Definite Article", "Pronoun", "Interjection", "Preposition", "Conjunction",
          "Plural", "Adverb", "Noun Phrase", "Noun", "Verb (usu participle)",
          "Verb (intransitive)", "Verb (transitive)", "Adjective"),
  certainty = 1:13
)

#join the certainty rankings to the data
pos_pos <- pos_pos %>%
  left_join(pos_certainty, by = "pos")

#filter to keep only the most certain POS for each word
pos_pos_filtered <- pos_pos %>%
  group_by(word) %>%
  filter(certainty == min(certainty)) %>%
  ungroup()

#join certainty rankings to data
neg_pos <- neg_pos %>%
  left_join(pos_certainty, by = "pos")

#apply the filter
neg_pos_filtered <- neg_pos %>%
  group_by(word) %>%
  filter(certainty == min(certainty)) %>%
  ungroup()

#reattach tne NULLs
pos_data <- rbind(pos_pos_filtered, pos_pos %>% filter(is.na(pos)))
neg_data <- rbind(neg_pos_filtered, neg_pos %>% filter(is.na(pos)))

#remove clarifiers for verbs
pos_data$pos <- gsub("\\(usu participle\\)", "", pos_data$pos)
pos_data$pos <- gsub("\\(transitive\\)", "", pos_data$pos)
pos_data$pos <- gsub("\\(intransitive\\)", "", pos_data$pos)

neg_data$pos <- gsub("\\(usu participle\\)", "", neg_data$pos)
neg_data$pos <- gsub("\\(transitive\\)", "", neg_data$pos)
neg_data$pos <- gsub("\\(intransitive\\)", "", neg_data$pos)

#remove any words shared between the two 
pos_data <- pos_data %>% filter(!word %in% intersect(pos_data$word, neg_data$word)) %>% select(word, pos)
neg_data <- neg_data %>% filter(!word %in% intersect(pos_data$word, neg_data$word)) %>% select(word, pos)

#write to the workspace
write.csv(pos_data, "pos_data.csv", row.names = F)
write.csv(neg_data, "neg_data.csv", row.names = F)
