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
		@objects = {} # { id: obj }
		@_assocs = {} # { id: [ obj ] }
		@rack = hat.rack!

	to-json: ->
		j =
			objs: []
			assocs: []

		indexes = {}

		for id, obj of @objects
			j.objs.push [ obj.constructor.id, obj.to-json! ]
			indexes[obj.qid!] = j.objs.length - 1

		saved-assocs = {} # { a-id: Set(b-id) }

		for a-id, assocs of @_assocs
			saved-assocs[a-id] = new Set

			for b-id in assocs
				unless saved-assocs[b-id]?.has(a-id)
					j.assocs.push [ indexes[a-id], indexes[b-id] ]

				saved-assocs[a-id].add b-id

		j

	load-json: (j) ->
		objs = {}

		for obj, i in j.objs
			obj = ddb.registry.from(obj)
			objs[i] = obj
			@register obj

		for assoc in j.assocs
			@assoc objs[assoc[0]], objs[assoc[1]]

		@

	@from-json = (j) -> new @!.load-json(j)

	register: (obj) ->
		unless @objects[obj.qid!]?
			# throw new Error('That id is already registered: ' + util.inspect(obj))
		# else
			obj.registered @

			@objects[obj.qid!] = obj

			@rack.set(obj.qid!, obj)

		@

	all: (kind = ddb.Object) ->
		all = []

		for id, obj of @objects when obj instanceof kind
			all.push obj

		all

	assocs: (obj, kind = ddb.Object) ->
		assocs = @_assocs[obj.qid!]

		if assocs?
			assocs.map(~> @objects[it]).filter(-> it instanceof kind)
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

class ddb.Object
	registered: (db) ->
	id: -> throw new Error("#{@constructor.name} must implement id")
	to-json: -> throw new Error("#{@constructor.name} must implement to-json")
	qid: -> "#{@constructor.id}-#{@id!}"

class ddb.ID extends ddb.Object
	id: -> @_id
	inspect: -> "<#{@constructor.name}:#{@_id}>"
	registered: (db) ->
		if @_id?
			throw new Error('You\'re using an ID with multiple databases, that won\'t work')

		@_id = db.rack(@)

	to-json: -> {}
	@from-json = (j) -> new @

class ddb.Data extends ddb.Object
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