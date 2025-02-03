#this script is an attempt to divide authors up on the basis of their relative levels of innovativeness
#I think it's a dead end - innovation as defined here will inevitably end up as an arbitrary usage of a small sample of words

#pull in the libraries we need
library(dplyr)
library(factoextra)
library(reshape2)
library(tidyr)

#pull in the csvs
year_data <- read.csv("year_data.csv")
author_data <- read.csv("author_data.csv")
career_data <- read.csv("career_dates.csv")

#remove .csv from the file name column
author_data$file_name <- gsub(".csv", "", author_data$file_name)

#drop x column we don't need it
career_data$X <- NULL
colnames(career_data)[1] <- "file_name"

#join author data with career data
author_data <- left_join(career_data, author_data, by = "file_name")

#introduce rownames
rownames(year_data) <- year_data$file_name
rownames(author_data) <- author_data$file_name

#drop the columns we don't need
year_data$X <- NULL
year_data$file_name <- NULL

author_data$X <- NULL
author_data$file_name <- NULL

#full join year_data and author_data
data <- full_join(year_data, author_data)

#create a single distance object
data_dist <- dist(data)

#put this distance matrix in a more straightforwardly manipulable form
data_dist <- melt(as.matrix(data_dist), variable.names(c("to", "from")))

#replace numbers with strings to this end
replacement_values <- cbind(1:length(c(rownames(year_data), rownames(author_data))), c(rownames(year_data), rownames(author_data)))

#facilitate this
colnames(replacement_values) <- c("numbers", "names")

#turn data_dist and replacement_values into a tibble
data_dist <- data_dist %>% as_tibble()
replacement_values <- replacement_values %>% as_tibble()

#convert string columns into characters
data_dist$Var1 <- as.character(data_dist$Var1)
data_dist$Var2 <- as.character(data_dist$Var2)

#run the replacement procedure
data_dist$Var1 <- plyr::mapvalues(data_dist$Var1, replacement_values$numbers, replacement_values$names, warn_missing = T)
data_dist$Var2 <- plyr::mapvalues(data_dist$Var2, replacement_values$numbers, replacement_values$names, warn_missing = T)

#remove a:a distances
data_dist <- data_dist %>% filter(Var1 != Var2) %>% arrange(desc(value))

#remove distances which are going to authors rather than years
dist_from_authors_to_years <- data_dist[which(!is.na(as.numeric(data_dist$Var2))),]
dist_from_authors_to_authors <- data_dist[which(is.na(as.numeric(data_dist$Var2))),]

#change column name
colnames(career_data)[1] <- "Var1"

#to faciliate these joins
authors_to_years_careers <- left_join(dist_from_authors_to_years, career_data, by = "Var1") 
authors_to_authors_careers <- left_join(dist_from_authors_to_authors, career_data, by = "Var1")

#we don't want anyone from before 1830
authors_to_years_careers <- authors_to_years_careers %>% filter(Var2 >= 1830)

#those which are looking backwards
dist_back <- authors_to_years_careers %>% filter(median_pub_date > Var2)

#those which are looking forwards
dist_forward <- authors_to_years_careers %>% filter(median_pub_date < Var2)

#group and summarise transience and novelty by author
transience <- dist_back %>% group_by(Var1) %>% summarise(novelty = median(value))
novelty <- dist_forward %>% group_by(Var1) %>% summarise(transience = median(value))

#rejoin the data
data <- left_join(novelty, transience)

data <- left_join(data, career_data)

#calculate resonance, which is novelty less transience
data$resonance <- data$novelty - data$transience

#normalise the distribution
data$transience <- scale(data$transience)
data$novelty <- scale(data$novelty)
data$resonance <- scale(data$resonance)

#create quotas which novelty or resonance have to be above or below
novelty_higher_quota <- as.numeric(quantile(data$novelty, 0.70, na.rm = T))
resonance_higher_quota <- as.numeric(quantile(data$resonance, 0.70, na.rm = T))

novelty_lower_quota <- as.numeric(quantile(data$novelty, 0.3, na.rm = T))
resonance_lower_quota <- as.numeric(quantile(data$resonance, 0.3, na.rm = T))

#four categories: high novelty high resonance, high novelty low resonance, low novelty high resonance, low novelty low resonance
#four epochs: 1840 - 1880, 1880 - 1920, 1920 - 1960 and 1960 - 2000
#
as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance >= resonance_higher_quota & median_pub_date <= 1880) %>% arrange(desc(resonance)))

as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance >= resonance_higher_quota & median_pub_date >= 1880 & median_pub_date <= 1920) %>% arrange(desc(resonance)))

as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance >= resonance_higher_quota & median_pub_date >= 1920 & median_pub_date <= 1960) %>% arrange(desc(resonance)))

as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance >= resonance_higher_quota & median_pub_date >= 1960 & median_pub_date <= 2000) %>% arrange(desc(resonance)))

as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance <= resonance_lower_quota & median_pub_date <= 1880) %>% arrange(desc(resonance)))

as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance <= resonance_lower_quota & median_pub_date >= 1880 & median_pub_date <= 1920) %>% arrange(desc(resonance)))

#zweig bernard shaw [check] gide
as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance <= resonance_lower_quota & median_pub_date >= 1920 & median_pub_date <= 1960) %>% arrange(desc(resonance)))

#lovecraft penelope fitzgerald flann o'brien tolkien
as.data.frame(data %>% filter(novelty >= novelty_higher_quota & resonance <= resonance_lower_quota & median_pub_date >= 1960 & median_pub_date <= 2000) %>% arrange(desc(resonance)))

#gaskell harriet beecher stowe
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance >= resonance_higher_quota & median_pub_date <= 1880) %>% arrange(desc(resonance)))

#kipling jack london henry o
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance >= resonance_higher_quota & median_pub_date >= 1880 & median_pub_date <= 1920) %>% arrange(desc(resonance)))

#john dos passos sinclair lewis robert penn warren thomas wolfe f scott fitzgerald
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance >= resonance_higher_quota & median_pub_date >= 1920 & median_pub_date <= 1960) %>% arrange(desc(resonance)))

#don delillo walter jacken katherine anne porter solzheintsyn - [le carr john 1931] robert a heinlein el doctorow
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance >= resonance_higher_quota & median_pub_date >= 1960 & median_pub_date <= 2000) %>% arrange(desc(resonance)))

#anthony trollope thackeray walter scott ajesm fennimore cooper baron lytton disraeli
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance <= resonance_lower_quota & median_pub_date <= 1880) %>% arrange(desc(resonance)))

#william dean howells mark twain ford madow ford anthony trollope
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance <= resonance_lower_quota & median_pub_date >= 1880 & median_pub_date <= 1920) %>% arrange(desc(resonance)))

#GK Chesterton - Aldous Huxley
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance <= resonance_lower_quota & median_pub_date >= 1920 & median_pub_date <= 1960) %>% arrange(desc(resonance)))

#Sean O Faoláin
as.data.frame(data %>% filter(novelty <= novelty_lower_quota & resonance <= resonance_lower_quota & median_pub_date >= 1960 & median_pub_date <= 2000) %>% arrange(desc(resonance)))

#high innovation high influence - absolute distance between words backwards and forward
gaskell <- author_data[which(grepl("gaskell", rownames(author_data))),]
gaskell$median_pub_date <- NULL

#create two dataframes, one before gaskell's writing career and one after
before_gaskell <- year_data[rownames(year_data) < 1848,] %>% summarise(across(everything(), median))
after_gaskell <- year_data[rownames(year_data) > 1893 & rownames(year_data) > 1848,] %>% summarise(across(everything(), median))

#calculate the absolute distance between the before period and gaskell's work
dists_before <- cbind(colnames(gaskell), abs(as.numeric(before_gaskell - gaskell)), as.vector(before_gaskell < gaskell))

#express the distance as a percentage
dists_before[,2] <- as.numeric(dists_before[,2]) / sum(as.numeric(dists_before[,2])) * 100

#arrange dists in descending order
dists_before <- dists_before %>% as_tibble() %>% mutate(V2 = as.numeric(V2)) %>% arrange(desc(V2))

#calculate the absolute distance between the before period and gaskell's work
dists_after <- cbind(colnames(gaskell), abs(as.numeric(after_gaskell - gaskell)), as.vector(after_gaskell > gaskell))

#express the distance as a percentage
dists_after[,2] <- as.numeric(dists_after[,2]) / sum(as.numeric(dists_after[,2])) * 100

#arrange dists in descending order
dists_after <- dists_after %>% as_tibble() %>% mutate(V2 = as.numeric(V2)) %>% arrange(desc(V2))



crane <- author_data[which(grepl("crane stephen", rownames(author_data))),]
chandler <- author_data[which(grepl("chandler raymond", rownames(author_data))),]
acker <- author_data[which(grepl("acker kathy", rownames(author_data))),]

#high innovation low influence - what words account for the most variation backwards and the least forward
poe <- author_data[which(grepl("poe edgar allan", rownames(author_data))),]
wilde <- author_data[which(grepl("wilde oscar", rownames(author_data))),]
lovecraft <- author_data[which(grepl("lovecraft", rownames(author_data))),]
flann <- author_data[which(grepl("flann", rownames(author_data))),]

#low innovation high influence - 
bulwer <- author_data[which(grepl("rosina", rownames(author_data))),]
passos <- author_data[which(grepl("passos", rownames(author_data))),]
kipling <- author_data[which(grepl("kipling", rownames(author_data))),]
delillo <- author_data[which(grepl("delillo", rownames(author_data))),]

#low innovation low influence
disraeli <- author_data[which(grepl("disraeli", rownames(author_data))),]
conrad <- author_data[which(grepl("conrad joseph", rownames(author_data))),]
oconnor <- author_data[which(grepl("oconnor frank", rownames(author_data))),]
banville <- author_data[which(grepl("banville", rownames(author_data))),]

