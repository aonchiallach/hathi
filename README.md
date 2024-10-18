The HathiTrust is an online repository that provides page-level data of millions of books across non-fiction, novels, poetry and drama; Ted Underwood is the computational literary scholar who has published most extensively on what can be done with this material and my doctoral thesis drew from some summary files he and his collaborators made available online.

Out of a sense of completionism I want to see what claims about literary history can be verified by applying some machine learning models to the broader dataset.

Hathi iterates through every json, identifies how many pages of a given volume are written in English and writes the id to a txt file if this is > 70%. This takes a very long time to run, but is very much worthwhile, we get an attrition rate of just under 50%, I'll be putting the list of ids up on Google Drive once I'm further along in the project so others can benefit from it.

Metadata pulls the publication date, title and author from every English language json and writes them to a csv

A yet to be uploaded R file filter this enormous dataframe, removing all the fiction, poetry and drama entries that we know of and then a number of words indicative of non-fictive texts: the non-fiction is by far the largest genre within the corpus and is therefore likely to skew any classifier. It's a brute-force method [note to self: a neater alternative might be to look at Underwood's paper on this project, evaluate the % breakdowns and see if the fiction, poetry and drama ids we know of line up proportionate to the number of non-fictive texts we would expect to see before 1922, this could allow for their removal at one stroke]

Otherwise we are going to iterate through every json in English, excluding those most obviously non-fictive texts and group every word frequency by word and then by year. Every year will then vote for the 1000 most frequent words by proportional representation, once we have these top 1000 words then we'll take a look to see what normalisation procedures we need to run.

