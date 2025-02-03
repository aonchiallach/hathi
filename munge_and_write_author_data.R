#this script takes in all the author csvs with their median word frequency data and collapses it into a single dataframe

#load the libraries we need
library(readr)
library(dplyr)
library(purrr)
library(data.table)
library(factoextra)

#create a list of all the .csv files in the named directory
list_of_files <- list.files(path = "authors",
                            recursive = TRUE,
                            pattern = "\\.csv$",
                            full.names = TRUE)

#define the column types
col_spec <- cols(
  word_type = col_character(),
  median_relative_frequency = col_character()
)

#read each file with a filename identifier
read_csv_with_id <- function(file) {
  read_csv(file, col_types = col_spec) %>%
    #and add the filename as a column in its own right
    mutate(file_name = basename(file))
}

#load all files into a single data frame, one at a time
data <- map_dfr(list_of_files, read_csv_with_id)

#convert this numeric
data$median_relative_frequency <- as.numeric(data$median_relative_frequency)

#pivot
data <- data %>% tidyr::pivot_wider(values_from = median_relative_frequency, names_from = word_type, values_fill = 0)

#normalise
data[,2:dim(data)[2]] <- scale(data[,2:dim(data)[2]])

#write to directory
write.csv(data, "author_data.csv")
