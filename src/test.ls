require! util

ddb = require \ddb

node = new ddb.Node

people = [
	[ \John \Doe ]
].map ([ firstName, lastName ]) ->
	ddb.cell node,
		firstName: ddb.cell(firstName)
		lastName: ddb.cell(firstName)

console.log util.inspect(node.cells, depth: null)
console.log people.map -> it.buffer.toString!