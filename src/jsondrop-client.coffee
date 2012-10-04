# The client API
class JsonDrop
	@JSONDROP_DIR = '/jsondrop'
	constructor: ({dropboxAdapter, key}) ->
    throw new Error 'Require a dropboxAdapter or a dropbox key' unless dropboxAdapter or key
    if key
      @dropbox = new DropBoxAdapter(key: key).getDropbox()
    else
      @dropbox = dropboxAdapter.getDropbox()

  # Get the dropbox instance
  # TODO interact through adpater only
  getDropbox: -> @dropbox

  # Get the Node instance representing data at the path (or root if no path supplied)
  get: (path) ->
    p = if path then JsonDrop.normalizePath(path) else ''
    new Node(path: p, jsonDrop: @)

  _set: (node, val) ->
    serializedVal = JSON.stringify val
    @dropbox.writeFile JsonDrop.JSONDROP_DIR + node.path + '/val.json', serializedVal, (error, stat) =>
      throw new Error(stat) if error

  @normalizePath = (path) ->
    path.replace(///^/+///, '').replace(////+$///, '')

# Class representing a data endpoint
class Node
  constructor: ({@path, @jsonDrop}) ->
	   @value = null

  getVal: () ->
    @value

  setVal: (obj) ->
    @value = obj
    @jsonDrop._set(@, obj)
    @
