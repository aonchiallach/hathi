The HathiTrust is an online repository that provides page-level data of millions of books across non-fiction, novels, poetry and drama; Ted Underwood is the computational literary scholar who has published most extensively on what can be done with this material and my doctoral thesis drew from some summary files he and his collaborators made available online.

Out of a sense of completionism I want to see what claims about literary history can be verified by applying some machine learning models to the broader dataset.

Hathi iterates through every json, identifies how many pages of a given volume are written in English and writes the id to a txt file if this is > 70%. This takes a very long time to run, but is very much worthwhile, we get an attrition rate of just under 50%, I'll be putting the list of ids up on Google Drive once I'm further along in the project so others can benefit from it.

Years pulls the pubDate field from every English language json and writes id + year to a csv file