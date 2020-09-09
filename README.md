# B12


Exercise 1.1

Assumptions:

I just filtered the values with monthly_plan is null and assumed that event basic plan is paid
In my mock data I created 3 different subscription for monthly_plan as basic, premium and enterprise
Basically for all monthly_plans other than Null I calculated the conversion rate by grouping by source and dividing by total users.
	
Exercise 1.2
Assumptions:
I eliminated weekends by extracting day of week from event_timestamp and filtering out Saturdays and Sundays (6 and 0 respectively in SQLite)
I also filtered the events so that I only take events into account which has event_timestamp > creted_timestamp
I created cohorts by day
I calculated users who signed up within 1 day from users which have an event_type = ‘signup_flow_end’ which also occurred after created_timestamp.
 I have a question in here, how come a user have a record before event getting created. I guess the logic should be in this order, signup_start -> signup_end -> created_timestamp. But according to the relation on Users and Events table it looks like we can have Users with signup_start event. So I assumed we will have an associated user_id for each event in Events table even if that event is ‘signup_flow_start’. I used Users table’s created_timestamp and Events table’s event_timestamp to find whether a User finished signup_flow within 1 day.
Key Points:
At first I calculated each event’s analytics as separate but that required reading the same data multiple times for each event and Joining them by cohort dates. That might be acceptable when you have relatively small data with a data warehouse which doesn’t cost you by data scanned(like Redshift). But in Bigquery that query is more expensive since BigQuery does not have a fixed cost by cluster like Redshift, instead it bills you by both storage(almost negligible) and bytes scanned in total( you should be really careful in there) so instead I used some kind of “Pivotting” to convert the rows to columns by a bunch of CASE statements. 
Since our events table have a constraint on User_id and event_type we can do the Pivotting by using some CASE When clauses. But if we didnt have this kind of unique constraint then we would need to use window functions to make sure we dont lose any information. For example users might have started signup_flow, then just discarded it, then they could start the flow again at some point while this time finishing it. In that case we would need to track users action by consecutive actions. So a possible signup_flow_end in that case should occur after 2nd signup_flow_start since user already discarded first one etc.

Exercise 1.3
Assumptions:
I assumed that those are daily reports, so when we subtract Saturdays and Sundays, Mondays will be compared to Fridays by using a LAG function on respective column.
I created a View from previous exercise and used the outputs of that

Key Points:
In order to compare stats to previous day I used LAG function.
I created alerts depending on the stats, keeping in mind that we can have multiple alerts on a given day.
I created queries for each alert than appended them all together. I also added a query for no alert days with null values and appended that one as well.

Exercise 2
You need to use Pydantic, argparse and and haversine packages. I included a requirements.txt file so you can just run pip install -r requirements on your virtual environment to install dependencies.

I used Pydantic for modelling API requests and responses. Pure python classes makes it easier and results in more readable code in my opinion.
I tried to construct a layered layout where your application start from main, then in core layer you basically have your business constraints and in infra layer you use whatever clients you need. In this case infra layer has a kiwi_client which is an http_client configured to use kiwi APIs. In core layer we have business models and services which actually does the flight optimization.

When using Kiwi APIs I first used their search API to get airports by given city name. To find the main airport by a given city I sorted results by their ‘dst_popularity_score’, assuming that main airport of a given city is the most popular one. Then after finding airports I listed all the flights between from and to airports in next 24 hours and mapped the responses to a nested model in Pydantic. Model hierarchy is as follows:

FlightApiResponseModel -> FlightDataModel -> RouteModel -> RouteDistanceModel

Each FlightApiResponseModel has data which constructs FlightDataModel. Each flight data has multiple routes as RouteModel which has lat_from, lng_from, lat_to, long_to. Each RouteModel may contain multiple RouteDistanceModel. Each RouteDistanceModel have a distance calculated from lat,lngs of from,to and a price for that route. Dollars_per_km is calculated from price and total distances of all RouteModels of a RouteDistanceModel. 
Script returns best dollars_per_km for selected Route and the Route that leads to best dollars_per_km as well.
