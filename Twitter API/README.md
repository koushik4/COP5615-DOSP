# Implementing a Twitter-like engine using Actor Model in Erlang

## Problem Statment
Implementation of twitter-like engine using actor-model in Erlang. The main functionalities of this engine are 
- Register
- Tweet
- Retweet
- Subscribe
- Deliver tweets live(if possible)
- Query tweets by subscribed user. 
- Query tweets by Hashtag
- Query tweets by Mentions

## Architecture
### Register                                                   Subscribe                    
<img width="300" height="300" alt="image" src="https://user-images.githubusercontent.com/60289522/208280369-2a392c05-7dc1-4351-9566-332f440bdf9e.png" />  <img width="300" height="300" alt="image" src="https://user-images.githubusercontent.com/60289522/208280379-3697e9c3-b09d-4786-98d8-f4a137115343.png">

### Tweet                                                          Retweet 
<img width="300" height="500" alt="image" src="https://user-images.githubusercontent.com/60289522/208280412-5ad9ced1-75cc-46d0-b1ff-59a24a0b749e.png">  <img width="300" height="500" alt="image" src="https://user-images.githubusercontent.com/60289522/208280420-32403713-b294-4676-9d6f-2804d01488de.png">

### Query Tweet by hashtag                             Query Tweet by mention 	
<img width="350" height="300" alt="image" src="https://user-images.githubusercontent.com/60289522/208280428-45733d59-4864-4f6d-8fe6-30a406b6c7d1.png">  <img width="350" height="300" alt="image" src="https://user-images.githubusercontent.com/60289522/208280440-1eed5253-1711-4d2f-9323-6bce1182876b.png">

### Query Tweet by subscribed	
<img width="300" alt="image" src="https://user-images.githubusercontent.com/60289522/208280449-06240066-9b59-4221-ad62-bf31c86a7cc7.png">


## Responsibilities
### Profile Structure
<img width="546" alt="image" src="https://user-images.githubusercontent.com/60289522/208280689-f3f586ee-c99f-4043-b97e-2b9634b151a0.png">


### Supervisor Responsibilities
- Store updated
	- Username - Profile mapping
		- Hashtag - Tweets mapping
		- Mention - Tweets mapping
- Compute query results and send the message to respective user. 
- Redirect all requests to appropriate user.
### User Responsibilities
- Store Updated profile
- Update tweet, subscription, feed lists
- Send the tweet to subscribers.
- Live delivery of tweets to connected users
- Compute Hashtags, Mentions in the tweet. 
- Display search query results. 
Note: The maximum number of users that are active in the network is tested upto 10,000. At the 50,000 mark, the laptop started to hang. 
## Zipf Distribution (zeta distribution)
**Zipf Law** :frequency of the words 𝜶 1/priority rank
### Distribution(histogram plot)
<img width="205" alt="image" src="https://user-images.githubusercontent.com/60289522/208280699-35fdf394-5c07-42e6-b567-c28ba418d80f.png">

## Run Instructions
- Compile files
   ```
	c(helper).
	c(twitter).
	c(client).
  ```
- Get Supervisor Id
	`Id = twitter:get_server().`
- Generate Users
`L = helper:helper_get_usernames(1000,[],Id). `
## Results
### Scenario 1
When there are N active users in the network. M tweets have been communicated amongst users and their subscribers(+mentioned). 
The time taken for the most famous user(maximum subscribers) to successfully tweet is plotted against total number of users communicating in the network. 
**M= 5000**

<img width="413" alt="image" src="https://user-images.githubusercontent.com/60289522/208280709-b519daee-60ac-44e2-8252-5393e6c38c06.png">

### Scenario 2
When there are N active users in the network. M tweets have been communicated amongst users and their subscribers(+mentioned). 
The time taken to fetch all tweets which contains Hashtag H is plotted against total number of 
Tweets in the network. 
**N = 5000**

<img width="398" alt="image" src="https://user-images.githubusercontent.com/60289522/208280716-e02f2913-d52c-45cb-b427-2b07a857fcd7.png">

### Scenario 3
When there are N active users in the network. M tweets have been communicated amongst users and their subscribers(+mentioned). 
The time taken to fetch all tweets which contains Mentions m is plotted against total number of 
Tweets in the network.
**N = 5000**

<img width="356" alt="image" src="https://user-images.githubusercontent.com/60289522/208280723-71148b13-4bbf-4167-86a1-e8c99e54e3f9.png">

## Conclusion
Twitter-like engine using actor model in Erlang is successfully implemented. The architecture is partly p2p and partly server-client model(for querying and redirecting). The efficacy of this architecture has been tested with various scenarios and using zipf distribution. Scenario 1 has given an expected linear growth w.r.t the total number of users. The discrepancies in the scenario2, scenario3 is due to invalid search (hashtag not valid, invalid user). This architecture can be made more effective with more than one supervisor is distributed across the network. With the right number os supervisors, we can expect logarithmic performance for scenario 1. 

