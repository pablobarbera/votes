Tracking Twitter Users Tweeting Their Vote
=============

Source code to build the website at [www.pablobarbera.com/votes](http://www.pablobarbera.com/votes).

Summary of .R files
-------

* `functions.R` includes all the functions that are necessary to run the other two R files.
* `get_tweets.R` captures all tweets mentioning the strings `vote AND obama`, `vote AND romney` or `tweetyourvote` in intervals of 1 hour, transforms them from JSON into a dataframe, and stores them in a mySQL database on localhost.
* `analysis.R` queries the SQL server for a list of all the tweets in Ohio, Florida, and the entire US and uses regular expressions to compute how many are actual users tweeting who they voted for. After that, the .R file also summarizes the data for each state (this will go into the table on the bottom-right corner), and exports them to a .csv file that is uploaded to the server.

Notes
-------

* All times are EST.
* Location is based on the `location` field of each user's profile (for Ohio and Florida), and on the time zone (for the entire U.S.). 
* The smoothing parameter computes rolling averages over periods of 1 hour.
* I select only tweets that clearly indicate that the user actually voted (e.g. tweets such as `I just voted for...`), or those that suggest a clear voting intention. I do not exclude retweets and assume that a retweet is an endorsement in this context. The regular expressions are identical for both candidates to avoid biases as much as possible. A random sample of the text of 10 tweets is provided below (I will update this later). User names and other identifying information has been redacted.


Votes for Obama:
> + If our new president of the United States is mitt Romney were all gonna be sick please everyone vote tomorrow if you havent already! Obama
> + RT @keela618: Vote tomorrow.....We playing for keeps Obama baby                                                                           
> + RT @_itsmeC: I cant wait to vote tomorrow !!! Obama :)                                                                                    
> + EVERYONE MAKE SURE YOU GO VOTE THE LAST DAY IS TOMORROW LETS SHOW OBAMA WE GOT THIS BACK  @Obama2012                                     
> + I go vote tomorrow ! obama

Votes for Romney:
> + RT @DaveRamsey: I voted early for Romney for Pres., Corker for Senate, and Blackburn for Congress. None perfect, but share ideals. You v ...
> + So youre saying the country will be better off if I vote for Mitt Romney?   
> + I cant wait to vote tomorrow! MITT ROMNEY!....                                                                
> + RT @storleystorm: Hope everyone that can is going to vote tomorrow! Romney
> + A few hours voting can can dramatically change your life. I voted for Romney, Mack and David Rivera. I ask you to go out and vote tomorrow.
