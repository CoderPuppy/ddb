util = require \util
ddb  = require \./

db = new ddb.DB

class Person extends ddb.ID
	@id = \person

ddb.registry.register Person

class Name extends ddb.Data
	@id = \name
	@names = [ \type, \val ]
	# todo: maybe?
	@type = [ String, String ]

ddb.registry.register Name

[
	[ \John, \Doe ]
	[ \Jane, \Doe ]
].for-each ([ first, last ]) ->
	person = new Person
	db.register person

	first-name = new Name(\first, first)
	db.register first-name
	db.assoc person, first-name

	last-name = new Name(\last, last)
	db.register last-name
	db.assoc person, last-name

john-doe = new Person
db.register john-doe

first-name = new Name(\first, \John)
db.register first-name

last-name = new Name(\last, \Doe)
db.register last-name

db.assoc john-doe, first-name
db.assoc john-doe, last-name

db.assoc last-name, first-name

# console.log db.all(Name)
# console.log db.all(Name).map(-> db.assocs(it, Person))

# Name(last, Doe) -> Person -> Name(first)
q = new ddb.Query(db)

q.add new Name(\last, \Doe)
q.assoc Person
q.assoc Name
q.filter new Name(\first)

console.log q.run!

flatten = -> it.reduce(((acc, val) -> acc.concat(val)), [])

console.log db.assocs(new Name(\last, \Doe), Person)