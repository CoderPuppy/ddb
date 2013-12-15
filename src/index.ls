util = require \util
hat  = require \hat

ddb = exports

class ddb.DB
	->
		@objects = new Map # constructor => { id: obj }
		@_assocs = new Map # constructor => {  }
		@rack = hat.rack!

	register: (obj) ->
		objs = @objects.get(obj.constructor)

		unless objs?
			objs = {}
			@objects.set(obj.constructor, objs)

		unless objs[obj.id!]?
			# throw new Error('That id is already registered: ' + util.inspect(obj))
		# else
			obj.registered @

			objs[obj.id!] = obj

			@rack.set(obj.id!, obj)

		@

	all: (kind) ->
		objs = @objects.get(kind)

		if objs?
			all = []

			for id, obj of objs
				all.push obj

			all
		else
			[]

	assocs: (obj, kind = ddb.Object) ->
		all-assocs = @_assocs.get(obj.constructor)

		if all-assocs?
			assocs = all-assocs[obj.id!]

			if assocs?
				assocs.filter(-> it instanceof kind)
			else
				new Set
		else
			new Set

	assoc: (a, b) ->
		do ~>
			all-assocs = @_assocs.get(a.constructor)

			unless all-assocs?
				all-assocs = {}
				@_assocs.set(a.constructor, all-assocs)

			assocs = all-assocs[a.id!]

			unless assocs?
				assocs = []
				all-assocs[a.id!] = assocs

			assocs.push b unless ~assocs.index-of(b) # todo: b or b.id!

		do ~>
			all-assocs = @_assocs.get(b.constructor)

			unless all-assocs?
				all-assocs = {}
				@_assocs.set(b.constructor, all-assocs)

			assocs = all-assocs[b.id!]

			unless assocs?
				assocs = []
				all-assocs[b.id!] = assocs

			assocs.push a unless ~assocs.index-of(a) # todo: a or a.id!

		@

class ddb.Object
	registered: (db) ->
	id: -> throw new Error("#{@constructor.name} must implement id")

class ddb.ID extends ddb.Object
	id: -> @_id
	inspect: -> "<#{@constructor.name}:#{@_id}>"
	registered: (db) -> @_id = db.rack(@)

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