#==============================================================================
# FUNCTIONS USED TO CREATE THE TWITTER ELECTION TIMELINE
#==============================================================================

#==============================================================================
# EXTRACT TWEETS USING STREAMING API
#==============================================================================

getStream <- function(string, filename, time=10800, user, password){
        require(RCurl)
        # user and password
        userpwd <- paste(user, password, sep=":")
        # Strings to search
        string_nospace <- gsub(" ", "_", string)
        if (length(string)>1){
                string <- paste(string, collapse=",")
        }
        track <- paste("track=", string, sep="")
        #### Function: redirects output to a file
        WRITE_TO_FILE <- function(x) {
                if (nchar(x) >0 ) {
                        write.table(x, file=filename, append=T, 
                                row.names=F, col.names=F, quote=F, eol="")
        } }
        ### write the raw JSON data from the Twitter Firehouse to a text file (without locations)
        getURL("https://stream.twitter.com/1/statuses/filter.json",
                userpwd=userpwd,
                write = WRITE_TO_FILE,
                postfields = track,
                .opts = list(timeout = time, verbose = TRUE))
}

#==============================================================================
# PARSE TWEETS IN JSON TO DATA.FRAME
#==============================================================================

JSONtoDF <- function(JSONfile){
        require(rjson)
## Read the text file          
f <- JSONfile

## Function to make the reading process robust
## Source: http://stackoverflow.com/questions/8889017/handle-rjson-error-when-parsing-twitter-api-in-r
convertTwitter <- function(x) {
  ## ?Control
  z <- try(fromJSON(x))
  if(class(z) != "try-error")  {
    return(z)
  }
}

lines <- readLines(f, warn=FALSE)
results.list <- lapply(lines[nchar(lines)>0], convertTwitter)
                
# Function to parse tweet information
parse.tweet <- function(var, list=list){
        values <- rep(NA, length(list))
        missing <- sapply((sapply(list, '[[', var)), is.null)
        values[missing==FALSE] <- unlist(sapply(list, '[[', var))
        return(values)
}

# Function to parse user information
parse.user <- function(user.var, list=list){
        values <- rep(NA, length(list))
        user <- sapply(list, '[', "user")
        missing <- sapply(sapply(user, '[', user.var), is.null)
        values[missing==FALSE] <- unlist(sapply(user, '[', user.var))
        return(values)
}

# Function to parse location
parse.place <- function(place.var, list=list){
        values <- rep(NA, length(list))
        place <- if (!is.null(sapply(list, '[', "place"))) sapply(list, '[', "place") else vector("list", length(list))
        missing <- sapply(sapply(place, '[[', place.var), is.null)
        values[missing==FALSE] <- unlist(sapply(place, '[[', place.var))
        return(values)
}

# Function to parse coordinates
parse.coordinates <- function(list=list){
        values <- matrix(NA, ncol=2, nrow=length(list))
        coord <- sapply(sapply(list, '[', "coordinates"), '[', "coordinates")
        missing <- as.character(sapply(sapply(coord, '[[', "coordinates"), is.null))
        values[missing=="FALSE"] <- matrix(as.character(unlist(coord)[unlist(coord)!="Point"]), ncol=2, byrow=TRUE)
        return(values)
}


# Variables of interest, for each tweet and user
tweet.vars <- c("text", "retweet_count", "favorited", "truncated", "id_str", "in_reply_to_screen_name", "source", "retweeted", "created_at", "in_reply_to_status_id_str", "in_reply_to_user_id_str")
user.vars <- c("listed_count", "verified", "location", "id_str", "description", "geo_enabled", "created_at", "statuses_count", "followers_count", "favourites_count", "protected", "url", "name", "time_zone", "id", "lang", "utc_offset", "friends_count", "screen_name")
place.vars <- c("country_code", "country", "place_type", "full_name", "name", "id")


# Saves tweet and user information into memory
df.tweet <- as.data.frame(sapply(tweet.vars, parse.tweet, results.list, simplify=FALSE), stringsAsFactors=FALSE)
df.user <- as.data.frame(sapply(user.vars, parse.user, results.list, simplify=FALSE), stringsAsFactors=FALSE)
df.place <- as.data.frame(sapply(place.vars, parse.place, results.list, simplify=FALSE), stringsAsFactors=FALSE)
df.coord <- as.data.frame(parse.coordinates(results.list), stringsAsFactors=FALSE); names(df.coord) <- c("lon", "lat")


df <- cbind(df.tweet, df.user, df.place, df.coord)

cat(length(df$text), "tweets have been parsed")
return(df)
}

#==============================================================================
# CLEAN UNICODE STRING
#==============================================================================

clean.unicode <- function(variable){
unicode.errors <- c("\\\u0092", "\\\u0086", "\\\x8e", "\\\x8f", "\\\x84", "\\\x87", "\\\x88", "\\\x92", "\\\x96", "\\\x97", 
                                        "\\\xe7", "\\\xed", "\\\xbc", "\\\x9c", "\\\xf2", "\\\x86", "\\\xa1", "\\\x95", "\\\x9f", "\\\x9e",
                                        "\\#", "\\\x98", "\\\xf1", "\\\xec", "\\\x8d", "\\\U3e65653c", "\\\xc0", "'", "\\\xea", "\\\xbf",
                                        "\\\x8b", "\\\xab", "\\\xe1", "\\\U3e33383cc", "\\\x83ire/", "\\\xbb", "/", "\\\U3e33393c",
                                        "\\\x91", "\\\xc1", "\\\U3e33663c", "\\\xdc", "\\\xd1", "%", "&", "\\\x82", "\xed\xec", "\x8c", 
                                        "\\n", "\\t", "<U\\+[[:alnum:]]+>", "\\r", "\\\x8a", "\\\xc8", "\\\xc7", "\\\xb4", "\\\xa3", 
                                        "\\\xe8", "\\\xce", "\\\xc2")
unicode.corrected <- c("í", "á", "é", "é", "Ñ", "á", "ó", "í", "Ñ", "ó", "Á", "í", " ", "ú", "Ú", " ", " ", "i", "u", "u", "",
                                        "ò", "Ó", "I", "ç", "Ó", "¿", "", "Í", "o", "a", " ", " ", "É", " ", "a", " ", "í", "e", "i", "ó",
                                        "", "Í", " ", " ", "Ç", "", " ", " ", " ", "", "", "", "", "", "", "", "", "", "")
pb <- txtProgressBar(min=1,max=length(unicode.errors))
for (i in 1:length(unicode.errors)){ 
        variable <- gsub(unicode.errors[i], unicode.corrected[i], variable)
        setTxtProgressBar(pb, i)
}
return(variable)
}

#==============================================================================
# FORMAT TWITTER DATE IN POSIX
#==============================================================================

format.twitter.date <- function(datestring){
        datestring <- as.POSIXct(datestring, format="%a %b %d %H:%M:%S %z %Y")
        return(datestring)
}

#==============================================================================
# Identifies tweets that indicate a vote for Romney or Obama
#==============================================================================

romney.filter <- function(twitterDF){
    # strings that indicate a vote for romney
    votes.strings <- paste(
        "I (just )?vote(d)? (for )?(gov )?(governor )?(mitt )?romney|",
        "I('m )?(m )?(am )? votin(g)? for (gov )?(governor )?(mitt )?romney|",
        ".*vote(d)?.*romney2012.*romneyryan2012.*|",
        "(gov )?(governor )?(mitt )?romney (is )?gettin(g)? my vote|",
        "gettin(g)? my vote.*(gov )?(governor )?(mitt )?romney (is )?|",
        "(gotta|have to|got to) vote for (gov )?(governor )?(mitt )?romney|",
        "(vote|voted).*(today|tomorrow).*(gov )?(governor )?(mitt )?romney|",
        "proud to vote (for )?(gov )?(governor )?(mitt )?romney|",
        "vote.*early.*romney|",
        "early.*vote.*romney|",
        "tweetyourvote.*romney|",
        "romney.*tweetyourvote",
        sep="") 
    
    # strings that indicate a NO vote for Romney
    novotes.strings <- paste(
        "(vote|voted).*(today|tomorrow).*obama|",
        "vote.*early.*obama|",
        "early.*vote.*obama",
        sep="") 
    
    # applying regular expression
    romney.votes <- grep(votes.strings, twitterDF$text, ignore.case=TRUE)
    romney.novotes <- grep(novotes.strings, twitterDF$text, ignore.case=TRUE)
    return(romney.votes[romney.votes %in% romney.novotes == FALSE])
}

obama.filter <- function(twitterDF){
    # strings that indicate a vote for obama
    votes.strings <- paste(
        "I (just )?vote(d)? (pres )?(president )?(barack )?obama|",
        "I('m )?(m )?(am )? votin(g)? (for )?(pres )?(president )?(barack )?obama|",
        ".*vote(d)?.*obama2012.*obamabiden2012.*|",
        "(pres )?(president )?(barack )?obama (is )?gettin(g)? my vote|",
        "gettin(g)? my vote.*(pres )?(president )?(barack )?obama (is )?|",
        "(gotta|have to|got to) vote for (pres )?(president )?(barack )?obama|",
        "(vote|voted).*(today|tomorrow).*(pres )?(president )?(barack )?obama|",
        "proud to vote (for )?(pres )?(president )?(barack )?obama",
        "vote.*early.*obama|",
        "early.*vote.*obama|",
        "tweetyourvote.*obama|",
        "obama.*tweetyourvote",
        sep="")
    # strings that indicate a NO vote for obama
    novotes.strings <- paste(
        "(vote|voted).*(today|tomorrow).*romney|",
        "vote.*early.*romney|",
        "early.*vote.*romney",
        sep="")
    
    # applying regular expression
    obama.votes <- grep(votes.strings, twitterDF$text, ignore.case=TRUE)
    obama.novotes <- grep(novotes.strings, twitterDF$text, ignore.case=TRUE)
    return(obama.votes[obama.votes %in% obama.novotes == FALSE])
}

#==============================================================================
# Summarizes vote-tweets for Obama and Romney in periods of 10 minutes
#==============================================================================

sum.tweets <- function(twitterDF, init="2012-11-05 00:00:00", end=Sys.time(), name){

    # creating all dates to be filled
    dates <- seq(as.POSIXct(init), as.POSIXct(end), by=60*60)

    # extracting date information
    twitterDF$created_at <- as.POSIXct(twitterDF$created_at)
    twitterDF$month <- strftime(twitterDF$created_at, format = "%m")
    twitterDF$day <- strftime(twitterDF$created_at, format = "%d")
    twitterDF$hour <- strftime(twitterDF$created_at, format = "%H")

    # collapsing dataset in periods of 1 hour
    twitterDF$counts <- 1
    twitterDF <- aggregate(twitterDF$counts, by=list(month=twitterDF$month, day=twitterDF$day,
        hour=twitterDF$hour), FUN=sum)
    twitterDF$date <- as.POSIXct(paste("2012-", sprintf("%02s", twitterDF$month), "-", 
        sprintf("%02s", twitterDF$day), " ", sprintf("%02s", twitterDF$hour), 
        ":00:00", sep=""))
    twitterDF$date <- as.POSIXct(twitterDF$date, tz="EST") + 7200

    # merging with sequence of dates
    twitterDF <- merge(data.frame(date=dates), twitterDF, all.x=TRUE)

    # subsetting and cleaning dataframe
    twitterDF <- twitterDF[,c("date", "x")]
    twitterDF$x[is.na(twitterDF$x)] <- 0
    names(twitterDF) <- c("date", name)

    return(twitterDF)
}


