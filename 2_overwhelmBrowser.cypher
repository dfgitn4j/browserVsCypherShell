// 2. This query runs fast, but will likely overwhelm the Neo4j Browser rendering for the created graph
MATCH paths=(:Node)-[:PARENT_OF*]->() RETURN paths