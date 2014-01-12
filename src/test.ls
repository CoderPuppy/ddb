util = require \util
ddb  = require \./

na = new ddb.Node

# na.on \assoc, (a, b) ->
# 	console.log '%s is now associated with %s', util.inspect(a), util.inspect(b)

# na.on \register, -> console.log('new cell: %s', util.inspect(it))

person-kind = new ddb.ID
person-kind.inspect = -> \Person
na.register person-kind

Person = class extends ddb.ID
	inspect: -> "<Person#{super!}>"
	registered: (node) ->
		super node
		node.assoc this, person-kind
	@id = \person
ddb.registry.register Person

[
	[ \John \Doe ]
	[ \Jane \Doe ]
	[ \Sally \Doe ]
].for-each ([ first, last ]) ->
	person = new Person
	na.register person
	# na.assoc person, person-kind

	first-name = new ddb.Data(\first, first)
	na.register first-name
	na.assoc person, first-name

	last-name = new ddb.Data(\last, last)
	na.register last-name
	na.assoc person, last-name

# Name(last, Doe) -> Person -> Name(first)
q = new ddb.Query(na)

q.add new ddb.Data(\last, \Doe)
q.assoc! # Person
q.filter-assoc person-kind
q.assoc! # Name
q.filter-out na
q.filter new ddb.Data(\first)

console.log q.run!

nb = new ddb.Node

sa = na.create-stream!
sb = nb.create-stream!
sa.pipe(sb).pipe(sa)

console.log nb.assocs!

q = new ddb.Query(nb)

q.add new ddb.Data(\last, \Doe)
q.assoc! # Person
q.filter-assoc person-kind
q.assoc! # Name
q.filter-out na, nb
q.filter new ddb.Data(\first)

console.log q.run!