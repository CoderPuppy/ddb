# Dynamic Database
**A basic graph database**

**Note: This requires ES6 Collections - Enable them with --harmony-collections**

## Overview
There are two types of objects (by default):

- **Identity Objects** -- Purely identity, no state, the id is random
- **Data Objects** -- Purely data, the id is based on the data

You can register objects into a database and associate two objects together.
To get the objects back you can either get all objects of a type or get all associated objects of an object (optionally restricting it to a type).

## Usage
**DB**

- *register(Object)*: Register an object with the database
- *assoc(a: Object, b: Object)*: Associate *a* with *b*
- *assocs(obj: Object, [kind: Kind])*: Get all the objects associated with *obj* of kind: *kind*
- *all(kind: Kind)*: Get all objects of kind: *kind*

**Object**

- *registered(db: DB)*: Callback for when it's registered with a database
- *id()*: ID for this object, abstract

**Data**

- *new Data(data...)*: Create a new data object with data: *data*

**ID**

Don't use one of these with multiple databases - only the last one you register it with will work

## Example

```javascript
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
```