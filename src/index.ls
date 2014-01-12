crypto = require \crypto
{Buffer} = require \buffer

ddb = exports

class ddb.Node
	->
		@cells = {}

	register: (cell) ->
		@cells[cell.id] = cell

		for link in cell.links
			@register link.cell


class ddb.Cell
	->
		@links ?= []
		@id = crypto.createHash('sha256').update(@buffer).digest('hex')

		# TODO: this is temporary
		@str = @buffer.toString!

class ddb.JSONCell extends ddb.Cell
	(json) ->
		@links = []

		if typeof(json) == 'object'
			@data = {}
			storedJSON = {}

			for k, v of json

				if v instanceof ddb.Cell
					@links.push do
						id: v.id
						cell: v
						name: k

					storedJSON[k] = v.id

					if v instanceof ddb.JSONCell
						@data[k] = v.data
					else
						@data[k] = v
				else
					storedJSON[k] = v
		else
			@data = json
			storedJSON = json

		@buffer = new Buffer(JSON.stringify(storedJSON))
		super!

ddb.cell = (node, json) ->
	unless json?
		json = node
		node = undefined

	cell = new JSONCell(json)

	if node?
		node.register cell

	cell

convertForView = (json) ->
	if typeof(json) == 'object'
		res = {}

		for k, v of json
			if v instanceof ddb.JSONCell
				res[k] = v.json
			else
				res[k] = v

		res
	else
		json

convertForStorage = (json) ->
	if typeof(json) == 'object'
		storedJSON = {}

		for k, v of json
			if v instanceof ddb.Cell
				storedJSON[k] = v.id
			else
				storedJSON[k] = v

		storedJSON
	else
		json