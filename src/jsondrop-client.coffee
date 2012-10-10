if global? and require? and module?
  exports = global
  exports._ = require("underscore")

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

  @pathFor = (node, file) ->
    filePart = if file then '/' + file else ''
    return @JSONDROP_DIR + node.path + filePart

  _clear: (node) ->
    @dropbox.remove JsonDrop.pathFor(node), (error, stat) =>

  _set: (node, val) ->
    @_clear node
    return @_delete(node) if val is null
    return @_setArray(node, val) if val instanceof Array
    return @_setObject(node, val) if val instanceof Object
    return @_setScalar(node, val)

  _setScalar: (node, scalar) ->
    serializedVal = JSON.stringify scalar
    @dropbox.writeFile JsonDrop.pathFor(node, 'val.json'), serializedVal, (error, stat) =>
      throw new Error(stat) if error

  _setArray: (node, array) ->
  	idx = []
  	_.each array, (item, i) =>
  	  new Node(path: node.path + '/_' + i, jsonDrop: @).setVal(item)
  	  idx .push '_' + i
    serializedVal = JSON.stringify idx
    @dropbox.writeFile JsonDrop.pathFor(node, 'array.json'), serializedVal, (error, stat) =>
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
