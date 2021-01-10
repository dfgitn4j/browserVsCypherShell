
# Where’s My Neo4j Cypher Query Results 😠 ⚡️ ⁉️

Why a Cypher query run in the Neo4j Browser may not return in a reasonable amount of time, what is happening, and what you can do about it.

***Note:** The content of this post is relevant to the Neo4j Browser version 4.2.0 and below as of January, 2021. Your “mileage may vary” as the Neo4j Browser is continually being improved. *

![A pickup truck and a race car can have the same engine. That’s where the similarities stop. Image From cars.com “[Weekend Toy Challenge: Ford F-150 Raptor Vs. McLaren 570GT](https://www.cars.com/articles/weekend-toy-challenge-ford-f-150-raptor-vs-mclaren-570gt-1420695479249/)”](https://cdn-images-1.medium.com/max/2000/1*CjKobhN4bFnRiv711pSseQ.png)*A pickup truck and a race car can have the same engine. That’s where the similarities stop. Image From cars.com “[Weekend Toy Challenge: Ford F-150 Raptor Vs. McLaren 570GT](https://www.cars.com/articles/weekend-toy-challenge-ford-f-150-raptor-vs-mclaren-570gt-1420695479249/)”*
> # Short version. Cypher query not returning when running in Neo4j Browser? It may not be the query execution time. Steps to mitigate include using aggregations, the PROFILE and EXPLAIN directives, cypher-shell and / or Neo4j Bloom. Read on if the scenarios that call for using these options and how to use them are not apparent. 

Originally the title of the post was going to play off of the “Ford vs. Ferrari” movie theme, but it occurred to the author that the real comparison is a Ford vs. Ford scenario. The Neo4j Browser is by far, the number one multi-utility “pickup truck” tool used to write Cypher queries and interact with a Neo4j database. The majority of Cypher queries run in the Neo4j Browser have no issues displaying an interactive graph visualization. Unfortunately, there are times when queries run through the Neo4j Browser start “taking a long time to run”. This situation is where performance and utility can unknowingly be at cross purposes. ***Neo4j users often equate the time it takes for the graph visualization or rendering of results of a Cypher query in the Neo4j Browser to database query performance.*** At first glance, this is a perfectly reasonable assumption. The reality is that it can be the rendering of the query results that is taking time, not the query execution. Assuming that the query response time is measured by when the visualization is produced can result in potentially invalid and costly conclusions, such as “I must re-write my query and / or restructure my database”. 

The goal of this post is to provide Neo4j Browser users with ways to determine if it’s a query’s performance or the visualization that is the culprit when query execution seems slow, and what other options exist. The workflow is very simple:

1. Determine if it’s the Neo4j Browser or the query execution that is keeping a visualization from being displayed. 

1. If it is the Neo4j Browser visualization, then try different query techniques and / or a different tool. 

1. Investigate why the query is slow to return if it’s not the visualization.

What the post does not take into consideration the larger context of concurrency, resource and database and query design and utilization. That’s a much bigger topic!

## The Maintenance Pits: Understanding Neo4j tool options and a little on how they work
> Go to the “Starting Line” section of this post if you understand the difference between the Neo4j Browser, cypher-shell and Neo4j Bloom.

### 1. The Neo4j Browser is the universal pickup truck

![Figure 1. Neo4j Browser force-directed layout](https://cdn-images-1.medium.com/max/2000/1*6UJgbjzWMGwbEGMNy4D4Pg.jpeg)*Figure 1. Neo4j Browser force-directed layout*

 The browser delivers an easy to use, metadata supported environment for developing Cypher queries with the interactive, force-directed graph visualization being the most popular output. The utility of the Neo4j Browser for developers cannot be understated and it will continue to be the main development interface for the majority of Neo4j users.  There’s query history, saving favorites, multi-statement execution, graph visualization export, graph gists available through the :play command, and is continuously being improved (*hint:* check out the :edit command if you haven’t already). The browser provides the pickup truck utility needed when writing Cypher and working with a Neo4j database. What many users do not realize is that there is **an *overhead cost*** for providing that utility that is bounded by the web browser environment it runs in. The processing to build an interactive visualization on a large graph data set can manifest itself by not responding in a reasonable amount of time. The irony is that the Neo4j Browser is almost a victim of its own success. Users get comfortable with the typical fast query and visualization response times, and then find themselves distressed and lost when immediate gratification is not forthcoming. 

### 2. Neo4j cypher-shell as the race car

[***cypher-shel](https://neo4j.com/docs/operations-manual/current/tools/cypher-shell/#cypher-shell-about)l***, a lightweight and bare bones command line tool for running Cypher queries with minimal to no formatting. This makes ***cypher-shell*** the low overhead, low functionality, but fast “race car” option.  ***cypher-shell*** works with the Neo4j Enterprise and Community editions.

### 3. A different kind of pickup truck provided by Neo4j Bloom

[***Neo4j Bloom](https://neo4j.com/product/bloom/)*** Neo4j Bloom is a different type of “pickup truck” tool designed for end-users and analysts. Users can navigate and query the graph *without* using Cypher. Bloom does this by using the structure of the graph to interactively suggest and guide users as they traverse through a graph. It also can visualize a much larger set of data than is possible in the Neo4j Browser. It has formatting, display, and extensibility capabilities that are well past what we can cover here. Bloom can be a very useful tool for developers even if much of the functionality is targeted at end-users. I often use Neo4j Bloom in conjunction with the Neo4j Browser when looking at a client’s graph for the first time. It allows me to easily navigate large and complex graph structures without writing custom Cypher queries.

***Caveat with Neo4j Bloom**. *Neo4j Bloom  requires the ***Enterprise*** version of the Neo4j database and does not work with the Neo4j Community Edition. Users can use Neo4j Bloom in two ways:

1. ***Through the Neo4j Desktop***. A single user Bloom installation is included with the Neo4j Desktop. Databases created from within the Neo4j Desktop run a free Developer License of the Neo4j Enterprise Edition. 

1. **Through an Neo4j Enterprise Edition database installation**. This requires Neo4j Bloom to be installed on the server and a Bloom activation key.

## Starting Line: The Neo4j Browser and what it’s doing

### 50 nodes -> 70 relationship: “Arrgh! Query!!! 🙀” vs. “Yeah! Query!!! 😺” 

![Figure 2. The “Spinning dots”. Where’s me lines, arrows and bouncing bubbles?](https://cdn-images-1.medium.com/max/2000/1*-kNby_yzueZ4OjIlS7-9Uw.gif)*Figure 2. The “Spinning dots”. Where’s me lines, arrows and bouncing bubbles?*

The motivation for this post is from seeing Neo4j Browser users getting frustrated when running a query that takes a long time to get back a result. The first thought is ***IT MUST BE THE DATABASE RUNNING SLOW. The agony *😖*!*** As discussed above, the issue could be caused by the overhead of rendering the returned data in the Neo4j Browser, ***not*** ***that underlying query is slow***. It is completely reasonable to assume that the database query is what is causing the delay even though often it’s not.

### What is the Neo4j Browser graph visualization really displaying?

Let’s use a simple acyclic graph structure to illustrate how even a small set of data can result in a significant amount of processing needed for visualization. The example graph consists of nodes with a :Node label, that are related to each other by a :PARENT_OF relationship, each with a unique node_id field. 

![Figure 3. Example database schema](https://cdn-images-1.medium.com/max/2000/1*krLxc7pr2a3VJSto2Jwxyg.jpeg)*Figure 3. Example database schema*

The graph is intentionally small, containing only **50** :Node labeled nodes, and **70** :PARENT_OF relationships. It was generated using a [Neo4j apoc](https://neo4j.com/developer/neo4j-apoc/) procedure that generates a random graph using the [Erdos-Renyi](https://en.wikipedia.org/wiki/Erd%C5%91s%E2%80%93R%C3%A9nyi_model) model. The schema visualization is shown in *Figure 3 , *and the source Cypher statements are on [github](https://github.com/dfgitn4j/neo4jBrowserRenderExample). Why so small? To illustrate how even a small number of nodes and relationships can have a large number of unique paths through the graph (see “[The Graph Database Chronicles Episode 1](https://vimeo.com/412062101/f779f65d71)” if this seems strange to you).

The number of unique paths is not a problem unto itself, but can have an impact on the Neo4j Browser graph visualization that is not obvious. *Figure 4* shows the visual output of the the one and two hop :PARENT_OF relationship traversals between :Node nodes using the query MATCH paths=(:Node)-[:PARENT_OF*1..2]->() RETURN paths. Here’s where the flattened, interactive visual output of the Neo4j Browser can be misinterpreted. 

![Figure 4. One and two traversal Neo4j Browser interactive graph visualization](https://cdn-images-1.medium.com/max/2128/1*N77iditHR55k4LmshSL-Pg.jpeg)*Figure 4. One and two traversal Neo4j Browser interactive graph visualization*

*Figure 4* shows 47 nodes and 70 relationships displayed, even though the underlying query returns 170 unique paths. Why the discrepancy between what’s visualized and the underlying data set it represents? The Neo4j Browser transforms the multi-dimensional overlapping data into a 2D visual. The visualization is very useful for exploring query results with the unfortunate potential side effect of obscuring the actual amount of data returned. 

The 50 node / 70 relationship example graph has a total of 5,673 unique paths. A visualization of all the unique paths is not much different from *Figure 4*, but the underlying data is approximately a 3,000% increase over the 170 one and two hop traversal query paths. The query MATCH path=(:Node)-[:PARENT_OF*]->() RETURN path illustrates returning all the paths for any number of traversals. Running this in the Neo4j Browser would result in the “arrrgh! *Figure 2”* spinning dots. ***Not to worry!*** Turns out that the query is not the issue. 
> ⁉️ This is a good time for a reality check. What value would a flat visualization of the all 5,673 paths have? It should be asked what the goal of a query is, will the visualization add any value, or is it just eye candy 👀 ? For this example it would be hard to come up with valid reason for needing a flattened visualization of 5,673 unique paths. “But wait! I am looking for unrecognized patterns in my graph!” is a common quick response. A flattened force-directed layout is not going to give you this. What’s really being asked for is functionality for finding patterns  based on the labels, properties and relationships in the graph data. One option is to use the algorithms in the Neo4j [Graph Data Science Library](https://neo4j.com/product/graph-data-science-library/). This is a topic well past this post, but is very worthwhile to look into.

### Three simple ways to determine if the Neo4j Browser attempting to render a visualization is a red herring performance issue. 

**1The count() test. **As mentioned above, using the Cypher count() aggregation can be a an easy test to understand how much data a query is returning and getting an idea of the query performance characteristics. Notice two things when this query MATCH path=(:Node)-[:PARENT_OF*]->() RETURN count(path) is run:

1. The number of paths can be significant. In my case there are 5,673 unique paths through the database even though there are only 50 nodes and 70 relationships in the graph.

1. The query starts streaming results in 1ms and completes after 10ms. 

![Figure 5. Path count query](https://cdn-images-1.medium.com/max/2000/1*PEwrqGW3kpG9-V7OaVxMEg.jpeg)*Figure 5. Path count query*

The aggregation avoids having to return and render the interactive graph visualization. There’s no fun force-directed layout visual (which is of dubious value in this use case), but at least it is known that it’s not the query execution itself that’s the issue. 

**2Use the PROFILE query directive to avoid the default force-directed visual layout.** Using the [PROFILE](https://neo4j.com/docs/cypher-manual/current/query-tuning/how-do-i-profile-a-query/#how-do-i-profile-a-query) directive will show how the query was executed, the processing time and show the query execution steps as the initial output, avoiding the default graph visualization step. To see this in action, run the all paths query with the PROFILE command: PROFILE MATCH paths=(:Node)-[:PARENT_OF*]->() RETURN paths which shows the query executing in 11ms as shown in *Figure 6* below. If you then click on the graph visualization icon  as shown in *Figure 7*, you’ll likely end up waiting for the visualization to render as in *Figure 2*. The Neo4j Browser might have to be closed and reopened to continue on. 

![](https://cdn-images-1.medium.com/max/2000/1*n4rHcLGyghfrGAQMEUcY8g.jpeg)

![Figure 6 (left). Abbreviated query PROFILE / Figure 7 (right). Switch to graph visualization](https://cdn-images-1.medium.com/max/2000/1*JdkSvnt8PyZN5gOBBcrXWw.jpeg)*Figure 6 (left). Abbreviated query PROFILE / Figure 7 (right). Switch to graph visualization*

Consider using the approaches for working with the data in the following “Green Flag” section if the PROFILE command returns in a reasonable amount of time but takes too long to visualize as a graph. If PROFILE does not return in a reasonable amount of time, then it’s likely the query execution that is the culprit. Try running the query with EXPLAIN directive to see the expected query execution plan. Either optimize the query structure from there, or the consider steps similar to those discussed in the “Yellow Flag” section below.

**3 Use a LIMIT clause in your query, or reduce number of paths traversed**. This approach is useful for minimizing the results returned, allowing for the graph visualization to be displayed in the Neo4j Browser. This is not always appropriate as it changes the query. A LIMIT is simply added to the query:

MATCH path=(:Node)-[:PARENT_OF*]->() RETURN path LIMIT 200

While changing the path depth from 1 to 3 traversals is accomplished by:

MATCH path=(:Node)-[:PARENT_OF*1..3]->() RETURN path 

This obviously is a trial-and-error approach that sometimes elicits interesting observations that can change the premise of the original query. 

## Green Flag: It is the Neo4j Browser visualization that is the “performance” culprit

### What are my options if I want to work with the big old data set returned by the Cypher query? 

1 **Use [Neo4j Bloom](https://neo4j.com/product/bloom/)**¹, if it is an option. Bloom is a very useful visualization and graph exploration tool for end-users and analysts, but how does that help in this scenario where we want to see the output of a Cypher statement? Fortunately, Bloom allows for Cypher queries to be created and parameterized for use within the interface by creating a [custom search phrase](https://neo4j.com/docs/bloom-user-guide/current/bloom-tutorial/#search-phrases-advanced) (*Figure 8*). We can then execute the query that was problematic for the Neo4j Browser to see the visualization Bloom.

![Figure 8. Bloom create search phrase dialog box](https://cdn-images-1.medium.com/max/2000/1*7ymb4qMrNEa8llnq7kicjQ.jpeg)*Figure 8. Bloom create search phrase dialog box*

2 **Use [cypher-shell](https://neo4j.com/docs/operations-manual/current/tools/cypher-shell/#cypher-shell-about), **a** **simple to use, no extras command line utility for running Cypher queries. ***cypher-shel***l works with all Neo4j editions. 

***cypher-shell*** query results have rudimentary formatting that need very little processing to create the final output. I often use it from within the [Sublime Text Editor](https://www.sublimetext.com/) when developing Cypher queries². This is useful when I have a series of disjoint statements (e.g. create data, indexes, match, merge, etc.) to run in sequence, or I want to use git as a repository for my queries. 

You can find*** cypher-shell*** in the Neo4j install location bin subdirectory, or it can be installed standalone (see Cypher Shell section of the [Neo4j Downloads](https://neo4j.com/download-center/) page). Running ***cypher-shell*** in a terminal window launched from the Neo4j Desktop on a Macbook is shown below. It is the same process for Windows. 

![Launching a terminal window and running cypher-shell on a mac](https://cdn-images-1.medium.com/max/2000/1*r8y9m9Rfo8fHvsit7LVujg.gif)*Launching a terminal window and running cypher-shell on a mac*

👉 Using ***cypher-shell*** with the--format-plain option is one of the fastest ways to return query data and execution metrics without writing your own code. Output can be saved to a file or piped through a pager for a better user experience. 

## Yellow Flag: What to do if the Cypher query is not performing as wanted? 

### ✏️ That is a big subject! ☯


A blog post could never even begin to address the subject of the yin and yang of query and database performance. There’s just too much to cover and too many variables. Given that, there are some things to keep in mind and resources to help out: 

1. Like any database, the design and how well queries are written can affect performance. The good news is that being “schemaless”, it is very easy to provide multiple graph models in a single Neo4j database to meet different query requirements. The twist is understanding when and how to create an efficient graph model and queries. Fortunately there’s an incredible number of resources to help Neo4j developers and users. There’s a quick introduction to modeling in the [Neo4j Developer documentation](https://neo4j.com/developer/data-modeling/), and the no charge online courses from [Neo4j GraphAcadamy](https://neo4j.com/graphacademy/online-training/). These courses cover Cypher basics, thru advanced query writing and optimization, to database design and administration, etc. 

1. The [Neo4j Community web site](https://community.neo4j.com/) is a wonderful resource to ask specific questions and take advantage of the collective knowledge of the vast Neo4j user community. I will often go to [neo4j.community.com](https://community.neo4j.com/) for ideas when I’m trying to solve a problem, or am looking for new approaches to writing a complex Cypher pattern. Good chance that whatever it is you’re asking has already been addressed. On a side note, the Neo4j Community’s “This Week in Neo4j” and “Featured Community Member” often presents interesting user provided graph use case examples and real world projects using new approaches and technologies. I would have completely missed the “[***Using Neo4j withPySpark on Databricks](https://towardsdatascience.com/using-neo4j-with-pyspark-on-databricks-eb3d127f2245)***” post if I wasn’t a member of the Neo4j community.

1. Remember that the Neo4j graph database is a ***database***. Even though Neo4j is a very efficient graph database, the universal database resource trifecta of RAM, CPU and i/o still apply and are constrained by concurrent usage. You can’t fix what you can’t see, and there are many ways to monitor the resource usage of the Neo4j database and queries. The [Halin monitoring](https://neo4j.com/labs/halin/) tool developed by Neo4j Labs that is available as a GraphApp in the Neo4j Desktop is one of the easiest monitoring tools to start with.

1. Follow the [YagNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it) (**Y**ou **a**in’t **g**onna **N**eed **I**t) principle and good graph data modeling techniques. A generalized query will return all the properties for each node and relationship to Neo4j Browser for rendering. If every node in our example graph had 512K of property data, that would be ~3MB of data being returned to the Neo4j Browser for displayed in the property value box. That’s a lot of memory and cpu being used just in case a user clicks or hovers on an individual node or relationship visualization to see the property data. Having node properties available in a visualization is what you’d expect, but there’s only so much you can really load into our web based Neo4j Browser pickup truck. Not only is an unreasonable number of properties a stressor for the browser, but it can indicate an underdeveloped graph model. See this [series](https://medium.com/neo4j/graph-data-modeling-categorical-variables-dd8a2845d5e0) of blog posts for a quick introduction to modeling concepts and how a good model that is easier to understand and query will avoid this scenario.

1. This should be obvious, but sure you have a graph use case! It is so much fun and easy working with a Neo4j graph database that it is easy to try and apply it to scenarios where graph does not add any value. Watch this short [video](https://www.youtube.com/watch?v=keZURbOo4-M&feature=youtu.be) for a good introduction on identifying graph shaped problems

## 🏁 FINISH Line 🏆

Thank you for your time if you made this far. Please post any questions or comments as I am very interested in what readers think and am hoping to gain insight from any responses. 

**¹** Bloom requires the ***Enterprise*** version of the Neo4j database. Databases created from within the Neo4j Desktop run a free Developer License of the Neo4j Enterprise Edition. 

**²** More on the Sublime Text editor and ***cypher-shell*** coming in another blog post.
