user <- "TWITTER_USER"
password <- "TWITTER_PASSWORD"
dbname <- "SQL_DATABASE_NAME"
userSQL <- "SQL_USERNAME"
passwordSQL <- "SQL_PASSOWRD" 

#==============================================================================
# Download tweets mentioning strings
#==============================================================================

source("functions.R")

#==============================================================================
# Local download (restart every 60 minutes using cronjob)
#==============================================================================

filename <- tempfile()

tryCatch(getStream(string=c("vote obama", "vote romney", "tweetyourvote"), filename=filename, time=3600, user=user,
	password=password),	error=function(e) e)

while (exists("error")){
	message("Error found! Restarting...")
tryCatch(getStream(string=c("vote obama", "vote romney", "tweetyourvote"), filename=filename, time=3600, user=user,
	password=password),	error=function(e) e)	
}

#==============================================================================
# Parse JSON to DF
#==============================================================================

tweets <- JSONtoDF(filename)

# cleaning date format and text fields
tweets$created_at <- format.twitter.date(tweets$created_at)
tweets$location <- clean.unicode(tweets$location)

#==============================================================================
# Upload to SQL database
#==============================================================================

library(RMySQL)
drv = dbDriver("MySQL")
conn <- dbConnect(drv, dbname=dbname, user=userSQL,
 					password=passwordSQL, host="localhost")

## First commit (RUN ONCE)
# dbWriteTable(conn, "votes", tweets)
# dbDisconnect(conn)

dbWriteTable(conn, "votes", tweets, append=TRUE)

dbDisconnect(conn)