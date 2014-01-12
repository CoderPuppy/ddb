[cyphernet](http://github.com/dominictarr/cyphernet)

cells are just data; the id is the hash of the data; thus you can't change the data

An imaginary orm based on what I read on cyphernet:

```javascript
// Author
{
	_links: [ 'type' ],
	type: Author.id,
	name: 'CoderPuppy'
}

// Post
{
	_links: [ 'type', 'author' ],
	type: Post.id,
	author: author.id,
	content: 'DO NOT POST "foobarbaz"'
}

// Comment
{
	_links: [ 'type', 'post', 'author' ],
	type: Comment.id,
	author: author.id,
	post: post.id,
	content: 'I\'m posting "foobarbaz"'
}
```

The DDB way:

```javascript
// Author
{
	_links: {
		type: TypeAssoc.id
	},
	type: Author.id
	name: 'CoderPuppy'
}

// Post
{
	_links: {
		type: TypeAssoc.id,
		author: WrittenByAssoc.id
	},
	type: Post.id,
	author: author.id,
	content: 'DO NOT POST "foobarbaz"'
}

// Comment
{
	_links: {
		type: TypeAssoc.id,
		author: WrittenByAssoc.id,
		post: CommentedOn.id
	},
	type: Comment.id,
	author: author.id,
	post: post.id,
	content: 'I\'m posting "foobarbaz"'
}
```