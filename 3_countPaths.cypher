// 3.  Count the number of unique paths returned
MATCH paths=(:Node)-[:PARENT_OF*]->() RETURN count(paths)