through = require \through2
crypto  = require \crypto
xtend   = require \xtend
util    = require \util
hat     = require \hat
ts      = require \monotonic-timestamp

{EventEmitter: EE} = require \events

ddb = exports

ddb.registry = {}
let @ = ddb.registry
	@types = {}

	@from = ([ id, j ]) -> @types[id].from-json j
	@register = (type) ->
		if @types[type.id]?
			throw new Error("A cell type with that id: #{util.inspect(type.id)} is already registered")

		@types[type.id] = type

	@to-json = (cell) ->
		[ cell.constructor.id, cell.to-json! ]

class ddb.Cell extends EE
	registered: (db) ->
	id: -> throw new Error("#{@constructor.name} must implement id")
	to-json: -> throw new Error("#{@constructor.name} must implement to-json")
	qid: -> "#{@constructor.id}-#{@id!}"

	filter: (filter) -> filter == this or filter == @qid!

	pipe: (dest) ->
		@create-stream(writable: false).pipe(dest.create-stream(readable: false))
		dest

	create-stream: (opts = {}) ->


		stream = through(objectMode: true, (u, enc, cb) ->
			cb!
		)

		@on \_update, (u) ->
			stream.push u

		stream

	local-update: (d) ->
		@_update [ d, @qid! ]

	_update: (u) ->
		@apply-update(u)

class ddb.ID extends ddb.Cell
	(@_id) ->
	@id = \ddb:id
	id: -> @_id + ''
	inspect: -> "##{@_id}"
	registered: (node) ->
		# if @_id?
		# 	throw new Error('You\'re using an ID with multiple databases, that won\'t work')

		unless @_id?
			@_id = crypto.createHash(\sha1).update(node.id! + '' + "-#{ts!}-#{node.rack(@)}").digest(\hex)

	to-json: -> { id: @_id }
	@from-json = (j) -> new @(j.id)
ddb.registry.register(ddb.ID)

class ddb.Data extends ddb.Cell
	(...@data) ->
		if @constructor.names?
			for let name, i in @constructor.names
				@[name] = (new-val) ->
					if new-val?
						@data[i] = new-val
						@
					else
						@data[i]

	@id = \ddb:data

	inspect: ->
		[
			'(',
			@data.map(-> util.inspect(it)).join(', '),
			')'
		].join ''
	id: -> @data.map(JSON.stringify).join(\-)

	to-json: -> @data
	@from-json = (j) -> new @(...j)

	filter: (filter) ->
		if filter instanceof ddb.Data
			for d, i in filter.data
				return false unless d? and @data[i] == d

			return true

		super filter
ddb.registry.register(ddb.Data)

class ddb.Node extends ddb.ID
	@id = \ddb:node

	->
		super!

		@cells = {} # { id: cell }
		@_assocs = {} # { id: [ cell ] }
		@hist = {} # { id: creation update }
		@rack = hat.rack!

		@registered this
		@register this

	inspect: -> "<Node#{super!}>"

	register: (cell) ->
		# @local-update [ \r ddb.registry.to-json(cell) ]

		# cell = ddb.registry.from(d[1])

		unless @cells[cell.qid!]?
			cell.registered @

			@cells[cell.qid!] = cell

			unless cell == @
				cell.on \_update, (u) ~>
					@local-update [ \u, cell.qid!, u ]

			@assoc this, cell

			@emit \register, cell

		@

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

		@emit \assoc, a, b

		@

	assocs: (cell = this, filter) ->
		if @_assocs[cell.qid!]
			res = @_assocs[cell.qid!].map(~> @cells[it]) # todo: requesting

			if filter?
				res = res.filter(-> it.filter(filter))

			res
		else
			[]

	apply-update: (u) ->
		d = u[0]

		switch d[0]
		| \r =>
			cell = ddb.registry.from(d[1])

			@register cell

	history: ->
		hist = []

		for id, u of @hist
			hist.push u

		for id, cell of @cells
			hist = hist.concat(cell.history!)

		hist

	# create-stream: (opts = {}) ->
	# 	stream = through(objectMode: true, (u, enc, cb) ->
	# 		cb!
	# 	)

	# 	stream

	# from-json: (j) -> 
ddb.registry.register(ddb.Node)

class ddb.Query
	(@node, ...@base) ->
		unless @base.length
			@base.push @node

		@parts = []

	assoc: (filter) ->
		@parts.push new @@Assoc(filter)

	add: (...cells) ->
		@parts.push new @@Nodes(...cells)

	filter: (filter) ->
		@parts.push new @@Filter(filter)

	filter-assoc: (cell, deep) ->
		@parts.push new @@AssocFilter(cell, deep)

	filter-out: (...cells) ->
		@parts.push new @@FilterOut(...cells)

	run: ->
		@parts.reduce(((acc, part) ~> part.find(@node, acc)), @base)

	class @Assoc
		(@filter) ->

		find: (node, prev) ->
			prev.reduce (acc, cell) ~>
				acc = acc.slice!

				assocs = node.assocs cell, @filter

				for cell in assocs when acc.index-of(cell) == -1
						acc.push cell

				acc
			, []

	class @Nodes
		(...@cells) ->

		find: (node, prev) ->
			after = prev.slice!

			for cell in @cells when after.index-of(cell) == -1
				after.push cell

			after

	class @Filter
		(@filter) ->

		find: (node, prev) ->
			prev.filter(~> it.filter(@filter))

	class @AssocFilter
		(@cell, @deep = false) ->
			throw new Error('not implemented') if deep

		find: (node, prev) ->
			prev.filter(~> node.assocs(it).index-of(@cell) != -1)

	class @FilterOut
		(...@cells) ->

		find: (node, prev) -> prev.filter(~> @cells.index-of(it) == -1)