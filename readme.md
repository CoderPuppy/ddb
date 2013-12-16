# Dynamic Database
**A basic graph database**

## Overview
There are two types of nodes (by default):

- **Identity Nodes** -- Purely identity, no state, the id is random
- **Data Nodes** -- Purely data, the id is based on the data

You can register nodes into a database and associate two nodes together.
To get the nodes back you can either get all nodes of a type or get all associated nodes of an node (optionally restricting it to a type).

## Usage
**DB**

- *register(Node)*: Register an node with the database
- *assoc(a: Node, b: Node)*: Associate *a* with *b*
- *assocs(node: Node, [filter])*: Get all the nodes associated with *node* of that match filter: *filter*
- *all([filter])*: Get all nodes that match filter: *filter*

**Node**

- *registered(db: DB)*: Callback for when it's registered with a database
- *id()*: ID for this node, abstract
- *filter(filter)*: Returns whether this node matches the filter, if the filter is a kind that means whether this node is an instance of the kind

**Data**

If the constructor has a property called names, methods will be generated to get and set properties.
Example:

```javascript
var util = require('util')
var ddb = require('ddb')

function Name() {
	ddb.Data.apply(this, arguments)
}
Name.names = [ 'type', 'val' ]
util.inherits(Name, ddb.data)

var name = new Name('last', 'Doe')
name.type() == 'last'
name.val() == 'Doe'
```

- *new Data(data...)*: Create a new data node with data: *data*
- *filter(filter)*: If the filter is of the same type as this, it checks all the properties of the filter and (if it's not null or undefined) it compares them to our data at the same index

**ID**

Don't use one of these with multiple databases - only the last one you register it with will work

**Query**

These let you seperate the definition of what to find from finding them.

- *new Query(db, base... = [ db ])*: Creates a new query on the db: *db*, starting with objects: *base*
- *assoc(filter)*: Find all the nodes (that match the filter) associated with the current set
- *add(...nodes)*: Add nodes to the current set
- *filter(filter)*: Filter the current set by the filter
- *run()*: Find all the nodes

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