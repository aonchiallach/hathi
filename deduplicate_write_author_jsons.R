#this script ingests:
#a list of english-language texts from the HathiTrust
#a set of authors we don't want to analyse because they're anachronistic or because they write children's literature
#a list of texts verified as being prose fiction
#to produce a list of file names which can be definitively associated with an author

#pull in the libraries we need
library(tidyr)
library(dplyr)
library(stringr)
library(stringdist)
library(fuzzyjoin)

#substring right function
substrRight <- function(x, n){
  substr(x, nchar(x) - n + 1, nchar(x))
}

#load english-language paths
eng_texts <- readLines("engtexts.txt")

#texts which don't belong between 1800 - 2013 or are childrens' authors
anachronisms <- readLines("removal_authors.txt")
   
#load and clean multiHathi csv
data <- read.csv("multiHATHI.csv", stringsAsFactors = FALSE) %>%
  as_tibble() %>%
  #filter for english language fiction, valid author data and trim whitespace
  filter(fic == 1, lang == "eng", !is.na(author), trimws(author) != "") %>%
  mutate(
    #tidy up author column
    author = gsub("[^a-z0-9 ]", "", tolower(trimws(author))),
    title = gsub("[^a-z0-9 ]", "", tolower(trimws(title))),
    author = gsub(" from old catalog", "", author),
    author = gsub(" old catalog heading", "", author),
    author = gsub("from old catalog", "", author),
    author = gsub("old catalog heading", "", author),
    #apply corrections
    author = case_when(
      author == "andrews mary raymond shipman 1936" ~ "andrews mary raymond shipman d 1936",
      author == "barr robert 18501912" ~ "barr robert 18491912",
      author == "beck l adams 1931" ~ "beck l adams d 1931",
      author == "blasco ibez vicente 18671928" ~ "blasco ibanez vicente 18671928",
      author == "burdett charles 1815" ~ "burdett charles b 1815",
      author == "capes bernard edward joseph 1918" ~ "capes bernard edward joseph d 1918",
      author == "castle agnes 1922" ~ "castle agnes 18601922",
      author == "clifford w k mrs 1929" ~ "clifford w k mrs d 1929",
      author == "crockett s r 18601914" ~ "crockett s r 18591914",
      author == "marriott charles 1869" ~ "marriott charles b 1869",
      author == "wells carolyn 1942" ~ "wells carolyn 18621942",
      author == "croker b m 1920" ~ "croker b m d 1920",
      author == "edwards annie 1896" ~ "edwards annie d 1896",
      author == "francis m e 1930" ~ "francis m e d 1930",
      author == "fraser hugh mrs 1922" ~ "fraser hugh mrs d 1922",
      author == "gray maxwell 1923" ~ "gray maxwell d 1923",
      author == "jkai mr 18251904" ~ "jokai mor 18251904",
      author == "molesworth mrs 18421921" ~ "molesworth mrs 18391921",
      author == "ridge w pett 1930" ~ "ridge w pett d 1930",
      author == "sheldon georgie mrs 1843" ~ "sheldon georgie mrs b 1843",
      author == "alger horatio jr 18321899" ~ "alger horatio 18321899",
      author == "sagan franoise 19352004" ~ "sagan francoise 19352004",
      author == "lagerlf selma 18581940" ~ "lagerlof selma 18581940",
      author == "maurois andr 18851967" ~  "maurois andre 18851967",
      author == "morrow honor 18801940" ~  "morrow honore 18801940",
      author == "coward nol 18991973" ~ "coward noel 18991973",
      author == "gide andr 18691951" ~  "gide andre 18691951",
      author == "mhlbach l 18141873" ~ "muhlbach l 18141873",
      author == "mittelhlzer edgar" ~  "mittelholzer edgar",
      author == "nin anas 19031977" ~ "nin anais 19031977",
      author == "burke thomas 18871945" ~ "burke thomas 18861945",
      author == "eberhart mignon good 18991996" ~ "eberhart mignon g 18991996",
      author == "yonge charlotte mary 18231901" ~ "yonge charlotte m 18231901",
      author == "corbett elizabeth frances 1887" ~ "corbett elizabeth frances 18871981",
      author == "edgeworth maria 17671849" ~ "edgeworth maria 17681849",
      author == "guthrie a b jr 19011991" ~ "guthrie a b 19011991",
      author == "johnson pamela hansford 1912" ~ "johnson pamela hansford 19121981",
      author == "cortzar julio" ~ "cortazar julio",
      author == "jhabvala ruth prawer 1927" ~ "jhabvala ruth prawer 19272013",
      author == "coxe george harmon 1901" ~ "coxe george harmon 19011984",
      author == "household geoffrey 1900" ~ "household geoffrey 19001988",
      author == "vance louis joseph 1879" ~ "vance louis joseph 18791933",
      author == "coatsworth elizabeth 18931986" ~ "coatsworth elizabeth jane 18931986",
      author == "cohen octavus roy 1891" ~ "cohen octavus roy 18911959",
      author == "zola mile 18401902" ~ "zola emile 18401902",
      author == "forster margaret 1938" ~ "forster margaret 19382016",
      author == "le guin ursula k 1929" ~ "le guin ursula k 19292018",
      author == "mason f van wyck 1901" ~ "mason f van wyck 19011978",
      author == "white eliza orne 1856" ~ "white eliza orne 18561947",
      author == "cullum ridgwell 1867" ~ "cullum ridgwell 18671943",
      author == "goldman william 1931" ~ "goldman william 19312018",
      author == "mckenna stephen 1888" ~ "mckenna stephen 18881967",
      author == "sheldon charles m 18571946" ~ "sheldon charles monroe 18571946",
      author == "douglas amanda m 18311916" ~ "douglas amanda minnie 18311916",
      author == "dickens monica 1915" ~ "dickens monica 19151992",
      author == "trevor william 1928" ~ "trevor william 19282016",
      author == "ewing juliana horatia gatty 18411885" ~ "ewing juliana horatia 18411885",
      author == "newton harry l" ~ "newton harry l b 1872",
      author == "nathan robert 1894" ~ "nathan robert 18941985",
      author == "bradbury ray 1920" ~ "bradbury ray 19202012",
      author == "mahfuz najib 1911" ~ "mahfuz najib 19112006",
      author == "bower b m 18711940" ~ "bower b m 18741940",
      author == "bawden nina 1925" ~ "bawden nina 19252012",
      author == "de morgan william frend 18391917" ~ "de morgan william 18391917",
      author == "naipaul v s 1932" ~ "naipaul v s 19322018",
      author == "wiesel elie 1928" ~ "wiesel elie 19282016",
      author == "braddon m e 18371915" ~ "braddon m e 18351915",
      author == "cleary jon 1917" ~ "cleary jon 19172010",
      author == "lavin mary 1912" ~ "lavin mary 19121996",
      author == "hewlett maurice henry 18611923" ~ "hewlett maurice 18611923",
      author == "newby p h 1918" ~ "newby p h 19181997",
      author == "rice anne 1941" ~ "rice anne 19412021",
      author == "stern g b 1890" ~ "stern g b 18901973",
      author == "lustig arnot" ~ "lustig arnost",
      author == "hecht ben 18931964" ~ "hecht ben 18941964",
      author == "meade l t 18541914" ~ "meade l t 18441914",
      author == "borrow george henry 18031881" ~ "borrow george 18031881",
      author == "gray david 18701968" ~ "grayson david 18701946",
      author == "marriott charles 18691957" ~ "marriott charles b 1869",
      author == "fox john 18631919" ~ "fox john jr 18621919",
      author == "harrison harry" ~ "harrison harry 1925",
      author == "bosher kate lee langley 18651932" ~  "bosher kate langley 18651932",
      author == "austin mary 18681934" ~ "austin mary hunter 18681934",
      author == "boothby guy 18671905" ~ "boothby guy newell 18671905",
      author == "howitt mary 17991888" ~ "howitt mary botham 17991888",
      author == "derleth august william 19091971" ~ "derleth august 19091971",
      author == "jameson storm 18971972" ~ "jameson storm 18911986",
      author == "bacon josephine daskam 18761961" ~ "bacon josephine dodge daskam 18761961",
      author == "hale edward everett 18221909" ~ "hale edward everett sr 18221909",
      author == "castle agnes d 1922" ~ "castle agnes 18601922",
      author == "hanley james 1901" ~ "hanley james 18971985",
      author == "munro alice" ~ "munro alice 1931",
      author == "west morris l 1916" ~ "west morris 19161999",
      author == "mauriac franois 18851970" ~ "mauriac francois 18851970",
      author == "miln louise jordan mrs 18641933" ~ "miln louise jordan 18641933",
      author == "mackenzie compton sir 18831972" ~ "mackenzie compton 18831972",
      author == "doyle arthur conan sir 18591930" ~ "doyle arthur conan 18591930",
      author == "lowndes marie belloc 18681947" ~ "lowndes belloc 18681947",
      author == "la mottefouqu friedrich heinrich karl freiherr de 17771843" ~ "la mottefouque friedrich heinrich karl freiherr de 17771843",
      author == "wells carolyn d 1942" ~ "wells carolyn 18621942",
      author == "lessing doris may 1919" ~ "lessing doris 19192013",
      author == "sherwood mary martha 17751851" ~ "sherwood mrs 17751851",
      author == "hotchkiss chauncey crafts 18521920" ~ "hotchkiss chauncey c 18521920",
      author == "scott walter sir 17711832" ~ "scott walter 17711832",
      author == "tourge albion winegar 18381905" ~ "tourgee albion w 18381905",
      author == "irwin margaret" ~ "irwin margaret 18891967",
      author == "walpole hugh sir 18841941" ~ "walpole hugh 18841941",
      author == "hughes richard arthur warren 19001976" ~ "hughes richard 19001976",
      author == "besant walter sir 18361901" ~ "besant walter 18361901",
      author == "onions oliver" ~ "onions oliver 18731961",
      author == "george walter lionel 18821926" ~ "george w l 18821926",
      author == "phelps e stuart 18441911" ~ "phelps elizabeth stuart 18441911",
      author == "stockton frank r 18341902" ~ "stockton frank richard 18341902",
      author == "carleton will 18451912" ~ "carleton william 17941869",
      author == "herbert a p sir 18901971" ~ "herbert a p 18901971",
      author == "caine hall sir 18531931" ~ "caine hall 18531931",
      author == "payn james" ~ "payn james 18301898",
      author == "lever charles james 18061872" ~ "lever charles 18061872",
      author == "thirkell angela mackail 18901961" ~ "thirkell angela 18901961",
      author == "train arthur cheney 18751945" ~ "train arthur 18751945",
      author == "maf najb 19112006" ~ "mahfuz najib 19112006",
      author == "vidal gore 1925" ~ "vidal gore 19252012",
      author == "bront charlotte 18161855" ~ "bronte charlotte 18161855",
      author == "castle agnes d 1922" ~ "castle agnes 18601922",
      author == "wells carolyn d 1942" ~ "wells carolyn 18621942",
      author == "houston james d" ~ "houston james 19212005",
      author == "aldiss brian wilson 1925" ~ "aldiss brian w 19252017",
      author == "quillercouch arthur thomas sir 18631944" ~ "quillercouch arthur 18631944",
      author == "read opie percival 18521939" ~ "read opie 18521939",
      author == "roberts charles george douglas sir 18601943" ~ "roberts charles g d sir 18601943",
      author == "wells carolyn d 1942" ~ "wells carolyn 18621942",
      author == "deland margaret wade campbell 18571945" ~ "deland margaret 18571945",
      author == "barr amelia edith huddleston 18311919" ~ "barr amelia e 18311919",
      author == "glasgow ellen anderson gholson 18731945" ~ "glasgow ellen 18731945",
      author == "disraeli benjamin earl of beaconsfield 18041881" ~ "disraeli benjamin 18041881",
      author == "tautphus jemima montgomery freifrau von 18071893" ~ "tautphoeus jemima montgomery baroness 18071893",
      author == "garcia marquez gabriel 1928" ~ "garca mrquez gabriel 19272014",
      author == "macaulay rose dame" ~ "macaulay rose 18811958",
      author == "hyne charles john cutcliffe wright 18661944" ~ "hyne c j cutcliffe",
      author == "white william allen 18681944" ~  "knight william allen 18631957",
      author == "swan annie s 18591943" ~ "smith annie s swan 18591943",
      author == "hichens robert smythe 18641950" ~ "hichens robert 18641950",
      author == "swan annie s 18591943" ~ "smith annie s swan 18591943",
      author == "helme elizabeth d 1814" ~ "helme elizabeth 17431814",
      author == "helme elizabeth 1814" ~ "helme elizabeth 17431814",
      author == "helme elizabeth d 1816" ~ "helme elizabeth 17431814",
      author == "helme elizabeth d 1814" ~ "helme elizabeth 17431814",
      author == "bennett mrs 1808" ~ "bennett anna maria 17461808",
      author == "bennett mrs d 1808" ~ "bennett anna maria 17461808",
      author == "moriarty h m" ~ "henrietta maria moriarty 17811842",
      author == "moriarty henrietta maria" ~ "henrietta maria moriarty 17811842",
      author == "dacre charlotte 1782" ~ "dacre charlotte 17821825",
      author == "dacre charlotte b 1782" ~ "dacre charlotte 17821825",
      author == "cuthbertson misses" ~ "cuthbertson catherine",
      author == "lewis matthew g" ~ "lewis m g 17751818",
      author == "radcliffe ann 17641823" ~ "radcliffe ann ward 17641823",
      author == "smith charlotte" ~ "smith charlotte turner 17491806",
      author == "smith charlotte 17491806" ~ "smith charlotte turner 17491806",
      author == "goldsmith oliver 17301774" ~ "goldsmith oliver 17281774",
      author == "goldsmith oliver ca 17301774" ~ "goldsmith oliver 17281774",
      author == "ofaolain sean 1900" ~ "ofaolain sean 19001991",
      author == "ofaolin sen 19001991" ~ "ofaolain sean 19001991",
      author == "le carr john 1931" ~ "le carre john 1931",
      TRUE ~ author
    )
  ) %>%
  filter(!author %in% anachronisms) %>%
  #select relevant columns and arrange by year
  select(htid, year, title, author) %>%
  arrange(year) %>%
  #to faciliate deduplication
  distinct(title, author, .keep_all = TRUE)

#extract instances where we have eight figures at the end of an author's name, make it a column
data$dates <- as.numeric(substrRight(data$author, 8))

#divide these into birth and death dates
data$death_date <- as.numeric(substrRight(data$dates, 4))
data$birth_date <- as.numeric(substr(data$dates, 1, 4))

#filter out instances where books were published 3 decades after death, assign result to data success
data_success <- data %>% filter(year < death_date + 30)

#take everything else into data_failure
data_failure <- anti_join(data, data_success)

#and reduce this down to instances where dates are NAs
data_failure <- data_failure[is.na(data_failure$dates),]

#create a new column which takes the last four characters of a string when we have " d " there, NA when we don't
data_failure$death_date <- ifelse(grepl(" d ", data_failure$author), 
                                  substr(data_failure$author, nchar(data_failure$author) - 3, nchar(data_failure$author)), 
                                  NA)

#do the same for " b " 
data_failure$birth_date <- ifelse(grepl(" b ", data_failure$author), 
                                  substr(data_failure$author, nchar(data_failure$author) - 3, nchar(data_failure$author)), 
                                  NA)

#convert these numeric
data_failure$birth_date <- as.numeric(data_failure$birth_date)
data_failure$death_date <- as.numeric(data_failure$death_date)

#attach data_success to data_failure where death date is thirty years after publication
data_success <- rbind(data_success, data_failure %>% filter(year < death_date + 30))

#data failure is everything not in data success
data_failure <- anti_join(data, data_success)

#and where dates are NAs
data_failure <- data_failure[is.na(data_failure$dates),]

#join data success and data failure
data <- rbind(data_success, data_failure) %>% distinct()

#standardise htid filenames
data <- data %>%
  mutate(
    htid = paste0(htid, ".json.bz2") %>%
      str_replace_all(":/", "+=") %>%
      str_replace_all("/", "="))

#prepare for joining
eng_texts <- tibble(eng_texts = eng_texts, htid = basename(eng_texts))

#perform left join and split into success/failure
data_one <- left_join(data, eng_texts, by = "htid")

data_success <- data_one %>%
  filter(!is.na(eng_texts)) %>%
  mutate(htid = eng_texts) %>%
  select(-eng_texts)

data_failure <- data_one %>%
  filter(is.na(eng_texts)) %>%
  select(-eng_texts) %>%
  filter(htid %in% eng_texts$htid)

#reassemble data and finalise paths
data <- bind_rows(data_failure, data_success) %>%
  rename(file_path = htid) %>%
  mutate(file_path = paste0("../../Volumes/My Passport for Mac/", file_path)) %>%
  filter(year >= 1800 & year <= 2010 & trimws(author) != "")

#change this column name
colnames(data)[2] <- "pub_date"

#group by author, summarise number of times each author appears and remove instances where this number falls below five
author_data <- data %>% group_by(author) %>% summarise(counts = n()) %>% filter(counts > 5 & trimws(author) != "")

#filter data down to where these authors appear 
author_data <- data %>% filter(author %in% author_data$author) %>% arrange(author)

#we're also interested in calculating average 'career dates'
career_dates <- author_data %>% group_by(author) %>% summarise(median_pub_date = round(median(pub_date)))

#write career dates to the directory
write.csv(career_dates, "career_dates.csv")

#write authors and file paths to the directory
write.csv(author_data, "author_jsons.csv", row.names = FALSE)
