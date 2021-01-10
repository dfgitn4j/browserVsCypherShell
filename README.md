## Cypher Queries Used In Medium Blog 

Blog post is [Found Here](https://medium.com/p/9c3b150e6e19)

Neo4j APOC procedures will need to be installed, see this [link](https://neo4j.com/developer/neo4j-apoc/) on how to install

There are two queries used as the basis for the blog content

- 1_createData.cypher
- 2_overwhelmBrowser.cypher
- 3_countPaths.cypher

Be aware that the apoc used to generate the graph, ```CALL apoc.generate.er(50,70,'Node', 'PARENT_OF')``` will generate a different graph each time it is run.
