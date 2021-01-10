// 1. Create data

// DELETE all data
MATCH (n) DETACH DELETE n;  

// clear all indexes and constraints
// add dbms.security.procedures.unrestricted=apoc.* to neo4j.conf file
CALL apoc.schema.assert({},{})
;

// Generate random graph with apoc (:Node)-[:PARENT_OF]->(:Node)
CALL apoc.generate.er(50,70,'Node', 'PARENT_OF')
;

// Give each node a unique easy read id 
MATCH (n) 
SET n:Node, n.node_id = id(n)
;

// Index / enforce uniqueness
CREATE CONSTRAINT con_node_id
ON (n:Node) ASSERT n.node_id IS UNIQUE
;


// remove the uuid field generated by the apoc - YagNI
MATCH (n:Node) 
REMOVE n.uuid
;

