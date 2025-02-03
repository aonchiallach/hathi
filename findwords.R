#this script pulls in two text files - a list of words and a novel
#it iterates through the latter in 500 word chunks and finds sections which are particularly dense with the former

pos <- scan("Desktop/pos_words.txt", what = "character")
neg <- scan("Desktop/neg_words.txt", what = "character")

pos <- gsub("'", "^", pos)
neg <- gsub("'", "^", neg)

corpus <- load.corpus(files = "all", corpus.dir = "Desktop/corpus", encoding = "UTF-8")

corpus <- txt.to.words.ext(corpus, corpus.lang = "English.all")

#create dummy variable
est_prop <- 0

  #for as long as x is
  for (i in 1:length(beautiful)) {
    
    #y is a vector that is 500 numbers in length, we use it to iterate through the text word by word
    y <- 0:499 + i
    
    #take a chunk that is 500 words in length, 
    #identify the number of negative and positive words
    #divide latter by former, assign result to prop
    prop <- length(intersect(beautiful[y], neg)) / length(intersect(beautiful[y], pos))
    
    if (is.na(prop)) {
      #print(i)
    } else if (prop > est_prop) {
      
      #print 
      print(beautiful[y])
      
      #assign this higher value to est_prop
      est_prop <- prop 
      
    }  else {
        #print(i)
    }
    
    }
  
      
    