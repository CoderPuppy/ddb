var ddb = require('ddb')
var util = require('util')

// Create a database
var db = new ddb.DB

// Create a person class of identity
function Person() {
	ddb.ID.call(this)
}
util.inherits(Person, ddb.ID)

// Create a name class of data
function Name() {
	ddb.Data.apply(this, arguments)
}
util.inherits(Name, ddb.Data)

// Create a new person
var johnDoe = new Person
db.register(johnDoe) // and register him with in the db
console.log('John Doe:', johnDoe)

// Create the first name
var firstName = new Name('first', 'John')
db.register(firstName) // register it
db.assoc(johnDoe, firstName) // associate it with John Doe

// Create the last name
var lastName = new Name('last', 'Doe')
db.register(lastName) // register it
db.assoc(johnDoe, lastName) // associate it with John Doe

console.log('John Doe\'s names:', db.assocs(johnDoe, Name))
console.log('People with a last name of Doe:', db.assocs(new Name('last', 'Doe')))