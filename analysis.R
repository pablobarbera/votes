dbname <- "SQL_DATABASE_NAME"
userSQL <- "SQL_USERNAME"
passwordSQL <- "SQL_PASSOWRD" 


#==============================================================================
# Create timeline with number of users 'tweeting their vote'
#==============================================================================

## opening connection to mySQL server

drv = dbDriver("MySQL")
library(XML)
conn <- dbConnect(drv, dbname=dbname, user=userSQL,
 					password=passwordSQL, host="localhost")

## empty table for summary statistics

results <- data.frame(
  where=rep(c("Ohio", "Florida", "US"), each=2),
  cand=rep(c("Obama", "Romney"), times=3),
  tweets=NA,
  users=NA)

#==============================================================================
# OHIO
#==============================================================================

## DOWNLOADING all tweets from Ohio

query <- "
SELECT text, created_at, id_str__1
FROM votes
WHERE  (location like '%ohio%'
    or location like '% oh%'
    or full_name like '%ohio%' 
    or full_name like '% oh%');
"

ohio.votes <- dbGetQuery(conn, query)

## CLEANING unicode characters
ohio.votes$text <- clean.unicode(ohio.votes$text)

## FILTERING votes for Obama and Romney

obama.votes <- obama.filter(ohio.votes)
romney.votes <- romney.filter(ohio.votes)

## getting summary statistics
results$tweets[results$where=="Ohio" & results$cand=="Obama" &] <- length(obama.votes)
results$tweets[results$where=="Ohio" & results$cand=="Romney"] <- length(romney.votes)

results$users[results$where=="Ohio" & results$cand=="Obama"] <- 
length(unique(ohio.votes$id_str__1[obama.votes]))
results$users[results$where=="Ohio" & results$cand=="Romney"] <- 
length(unique(ohio.votes$id_str__1[romney.votes]))

## SUMMARIZING in periods of 10 minutes for specified period

obama.votes <- sum.tweets(ohio.votes[obama.votes,], init="2012-11-04 18:00:00",
  end=Sys.time()+7200, name="Obama")

romney.votes <- sum.tweets(ohio.votes[romney.votes,], init="2012-11-04 18:00:00",
  end=Sys.time()+7200, name="Romney")

## MERGING data into a single dataframe

ohio.data <- merge(obama.votes, romney.votes)
ohio.data$date <- gsub("-", "/", ohio.data$date)

write.csv(ohio.data, file="ohiodata.csv", row.names=F, quote=F)

#==============================================================================
# FLORIDA
#==============================================================================

## DOWNLOADING all tweets from Florida

query <- "
SELECT text, created_at, id_str__1
FROM votes
WHERE  (location like '%florida%'
    or location like '% fl%'
    or full_name like '%florida%' 
    or full_name like '% fl%');
"

fl.votes <- dbGetQuery(conn, query)

## CLEANING unicode characters
fl.votes$text <- clean.unicode(fl.votes$text)

## FILTERING votes for Obama and Romney

obama.votes <- obama.filter(fl.votes)
romney.votes <- romney.filter(fl.votes)

## getting summary statistics
results$tweets[results$where=="Florida" & results$cand=="Obama"] <- length(obama.votes)
results$tweets[results$where=="Florida" & results$cand=="Romney"] <- length(romney.votes)

results$users[results$where=="Florida" & results$cand=="Obama"] <- 
length(unique(fl.votes$id_str__1[obama.votes]))
results$users[results$where=="Florida" & results$cand=="Romney"] <- 
length(unique(fl.votes$id_str__1[romney.votes]))

## SUMMARIZING in periods of 10 minutes for specified period

obama.votes <- sum.tweets(fl.votes[obama.votes,], init="2012-11-04 18:00:00",
  end=Sys.time()+5400, name="Obama")

romney.votes <- sum.tweets(fl.votes[romney.votes,],  init="2012-11-04 18:00:00",
  end=Sys.time()+5400, name="Romney")

## MERGING data into a single dataframe

fl.data <- merge(obama.votes, romney.votes)
fl.data$date <- gsub("-", "/", fl.data$date)

write.csv(fl.data, file="fldata.csv", row.names=F, quote=F)


#==============================================================================
# UNITED STATES
#==============================================================================


## DOWNLOADING all tweets from the US

query <- "
SELECT text, created_at, id_str__1, time_zone
FROM votes
WHERE  (time_zone like 'Alaska'
  or time_zone like 'Arizona'
  or time_zone like 'Atlantic Time (Canada)'
  or time_zone like 'Central Time (US & Canada)'
  or time_zone like 'Eastern Time (US & Canada)'
  or time_zone like 'Hawaii'
  or time_zone like 'Mountain Time (US & Canada)'
  or time_zone like 'Pacific Time (US & Canada)'
  or time_zone like 'Quito');
"

us.votes <- dbGetQuery(conn, query)

## CLEANING unicode characters
us.votes$text <- clean.unicode(us.votes$text)

## FILTERING votes for Obama and Romney

obama.votes <- obama.filter(us.votes)
romney.votes <- romney.filter(us.votes)

## getting summary statistics
results$tweets[results$where=="US" & results$cand=="Obama"] <- length(obama.votes)
results$tweets[results$where=="US" & results$cand=="Romney"] <- length(romney.votes)

results$users[results$where=="US" & results$cand=="Obama"] <- 
length(unique(us.votes$id_str__1[obama.votes]))
results$users[results$where=="US" & results$cand=="Romney"] <- 
length(unique(us.votes$id_str__1[romney.votes]))

## SUMMARIZING in periods of 10 minutes for specified period

obama.votes <- sum.tweets(us.votes[obama.votes,],  init="2012-11-04 18:00:00",
  end=Sys.time()+5400, name="Obama")

romney.votes <- sum.tweets(us.votes[romney.votes,], init="2012-11-04 18:00:00",
  end=Sys.time()+5400, name="Romney")

## MERGING data into a single dataframe

us.data <- merge(obama.votes, romney.votes)
us.data$date <- gsub("-", "/", us.data$date)

write.csv(us.data, file="usdata.csv", row.names=F, quote=F)

