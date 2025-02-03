# Introduction

The HathiTrust is an online repository that provides page-level data extracted from millions of books across hundreds of genres, broadly grouped in most analyses into four: non-fiction, novels, poetry and drama. Ted Underwood is the computational literary scholar who has written most extensively on what can be done with this material and my doctoral thesis drew from some summary files he and his collaborators made available online.

Out of a completionist impulse I wanted to see what claims about literary history can be verified by applying some machine learning models to the broader dataset and write this up in order to assist people who want to do the same thing.

# Methodology

## Get English-language texts

We start with hathi.ipynb, which iterates through every json, identifies how many pages of a given volume are written in English and if this figure > 70% of the total pages, writes the file id to the text file eng_texts, which is too big to push up here but I can make available to anyone who wants it. This takes a very long time to run, but is very much worthwhile, as there is an attrition rate of just under 50%. 

## Get metadata

metadata.ipynb pulls the publication date, title and author from every English language json and writes them to extracted_metadata.csv, also too large to push up but available on request.

## Deduplicate volumes / remove poetry, prose, drama

deduplicate_write_fiction_jsons.R takes: 

- eng_texts.txt

See above

- removal_authors.txt

a list of authors who are either anachronisms (Virgil, Homer, Chaucer) or are primarily poets, dramatists, travel writers, authors of children's literature, none of which I was interested in here. I wrote this file myself and identified a lot of these authors either through basic frequency analysis of the author column or through a number of subsequent exploratory clustering / modelling work that didn't come to anything: they kept presenting themselves as outliers for the obvious reason that poetry and children's literature stand out in a pile

- multihathi.csv

Andrew Piper and Sil Hamilton's [dataset](https://openhumanitiesdata.metajnl.com/articles/10.5334/johd.95) which contains metadata relating to 10.2 million works of fiction and non-fiction written from 1800 on 521 languages.

## Machine learning diversion

Initially my plan was to run an unsupervised machine learning analysis on everything: bibliographic and word-frequency data across all English-language texts in order to derive my own benchmarks for discriminant genre analysis so I could say something substantive about fiction, poetry and drama. 

My first obstacle and the most decisive one, was that I only have one machine and my processing power wasn't equal to millions of rows across a couple of thousand columns. I'm sure someone more capable than me could come up with some way of compensating for the vast skew in favour of non-fiction here without any labels (correlating terms in the metadata maybe) but this was beyond me / might be something I'll come back to.

Even if I did have a server though I think that after spending a bit of time with this stuff there is not enough poetry and drama in here to advance any long-term arguments about literary history outside of prose. Once we remove the anachronistic texts the sample size for certain years even into the nineteenth century is just to small and that's to leave aside the long stretches of the eighteenth century which are unaccounted for. 

I took my own corrected version of multihathi as a starting point for pulling in whatever I was interested in. I am hugely grateful to Piper and Hamilton and their collaborators for doing so much of this work in advance, as well as Ruairí Fahy who replied to me many times on Twitter and BlueSky with advice and recommendations, if you live in Limerick you should vote for him.

## Scraping jsons

All changes I made to multihathi are documented in deduplicate_write_fiction_jsons.R, the output of which gives scrape_jsons_by_year.ipynb a list to to iterate through in gathering word frequencies, grouping and outputting them into year-specific csv files.

## Pruning volumes

To the end of removing the influence of subsequent editions of books I decide to remove books published more than 30 years after the given author's date of death: a more or less arbitrary threshold beyond which I would assume any publications were re-issues and therefore already represented in the dataset.

The author field contains this birth / death date data but its not standard. Sometimes it appears relatively cleanly with two four digit years separated by two spaces and a hyphen, sometimes 'b.' or 'd' is intervening. The approach I adopted breaks off the harder cases and deals with them separately.

Again, the procedures I adopt here are the best that I could do according to time, resources, scope, technical capacity. I'm sure there are non-English texts from the fourteenth century in my analysis somewhere, just as there's mislabeled objects in the multihathi data or Underwood's paths (fictions_paths.txt, poetry_paths.txt, drama_paths.txt), but everyone running this project will do things their own way and the most salient point is in the aggregate, we have data we can be broadly certain of.

deduplicate_write_author_jsons.R does the same thing as scrape_jsons_by_year.ipynb except the csvs are grouped by author rather than year - as can be seen in author_jsons.csv. This shift in focus means we remove authors which are blank, and authors which appear less than five times: we take this as an indicator that the author in question has published less than five books and therefore, falls below a qualifying threshold. We also calculate career_dates here: the median date at which each author published.

## Analysis

findwords.R is the very simple means through which I relate words operating on the macro scale to texts on the level of the paragraph.

posnegwordsanalysis.R takes the year-specific csvs we compiled in scrape_jsons_by_years.ipynb and pulls them into a datatable. We calculate the total word use for every year and use removal_words to remove the words we don't want. Like the list of anachronistic authors this list was compiled over a reasonably long period of time, it is overwhelmingly names, but is also stuff like 'thirtythree' or 'y'.

replacement_words.csv overwhelmingly deals with the tendency whatever OCR software was used at the beginning of all this to read 's' as 'f'.

The top 10k words across every year is arrived at via proportional representation, we output the finished dataframe and also the words which increase or decrease their presence in literature over time pos.txt / neg.txt. We also have some part-of-speech analysis in there.

## Future work

influence_wip.R was a modelling exercise I only got desultory results from, might return to it in the future.