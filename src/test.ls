ddb = require \./

db = new ddb.DB

class Person extends ddb.ID

class Name extends ddb.Data
	# todo: maybe?
	@type = [ String, String ]

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

console.log db.assocs(john-doe)
console.log db.all(Name)
console.log db.assocs(new Name(\last, \Doe), Person)