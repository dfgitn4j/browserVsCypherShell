// 4. get the longest path
MATCH paths=(:Node)-[:PARENT_OF*]->() 
RETURN length(paths) as longestPathLength
ORDER BY longestPathLength DESC
LIMIT 1