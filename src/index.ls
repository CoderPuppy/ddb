util = require \util
hat  = require \hat

ddb = exports

ddb.registry = {}
let @ = ddb.registry
	@kinds = {}

	@from = ([ id, j ]) -> @kinds[id].from-json j
	@register = (kind) ->
		if @kinds[kind.id]?
			throw new Error("A kind with that id: #{util.inspect(kind.id)} is already registered")

		@kinds[kind.id] = kind

class ddb.DB
	->
		@nodes = {} # { id: node }
		@_assocs = {} # { id: [ node ] }
		@rack = hat.rack!

	to-json: ->
		j =
			nodes: []
			assocs: []

		indexes = {}

		for id, node of @nodes
			j.nodes.push [ node.constructor.id, node.to-json! ]
			indexes[node.qid!] = j.nodes.length - 1

		saved-assocs = {} # { a-id: Set(b-id) }

		for a-id, assocs of @_assocs
			saved-assocs[a-id] = new Set

			for b-id in assocs
				unless saved-assocs[b-id]?.has(a-id)
					j.assocs.push [ indexes[a-id], indexes[b-id] ]

				saved-assocs[a-id].add b-id

		j

	load-json: (j) ->
		nodes = {}

		for node, i in j.nodes
			node = ddb.registry.from(node)
			nodes[i] = node
			@register node

		for assoc in j.assocs
			@assoc nodes[assoc[0]], nodes[assoc[1]]

		@

	@from-json = (j) -> new @!.load-json(j)

	register: (node) ->
		unless @nodes[node.qid!]?
			# throw new Error('That id is already registered: ' + util.inspect(node))
		# else
			node.registered @

			@nodes[node.qid!] = node

			@rack.set(node.qid!, node)

		@

	all: (kind = ddb.Node) ->
		all = []

		for id, node of @nodes when node instanceof kind
			all.push node

		all

	assocs: (node, kind = ddb.Node) ->
		assocs = @_assocs[node.qid!]

		if assocs?
			assocs.map(~> @nodes[it]).filter(-> it instanceof kind)
		else
			[]

	assoc: (a, b) ->
		do ~>
			assocs = @_assocs[a.qid!]

			unless assocs?
				assocs = []
				@_assocs[a.qid!] = assocs

			assocs.push b.qid! unless ~assocs.index-of(b.qid!)

		do ~>
			assocs = @_assocs[b.qid!]

			unless assocs?
				assocs = []
				@_assocs[b.qid!] = assocs

			assocs.push a.qid! unless ~assocs.index-of(a.qid!)

		@

class ddb.Node
	registered: (db) ->
	id: -> throw new Error("#{@constructor.name} must implement id")
	to-json: -> throw new Error("#{@constructor.name} must implement to-json")
	qid: -> "#{@constructor.id}-#{@id!}"

class ddb.ID extends ddb.Node
	id: -> @_id
	inspect: -> "<#{@constructor.name}:#{@_id}>"
	registered: (db) ->
		if @_id?
			throw new Error('You\'re using an ID with multiple databases, that won\'t work')

		@_id = db.rack(@)

	to-json: -> {}
	@from-json = (j) -> new @

class ddb.Data extends ddb.Node
	(...@data) ->
	inspect: ->
		[
			@constructor.name,
			'(',
			@data.map(-> util.inspect(it)).join(', '),
			')'
		].join ''
	id: -> @data.map(JSON.stringify).join(\-)

	to-json: -> @data
	@from-json = (j) -> new @(...j)