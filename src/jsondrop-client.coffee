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

  # Create the dropbox path for the file at the node
  @pathFor = (node, file) ->
    filePart = if file then '/' + file else ''
    return @JSONDROP_DIR + node.path + filePart

  _clear: (node) ->
    @dropbox.remove JsonDrop.pathFor(node), (error, stat) =>

  _get: (node) ->
    @dropbox.readdir JsonDrop.pathFor(node), (error, entries) =>
      return null if error
      switch entries[0]
        when 'val.json' then @_getScalar node
        when 'array.json' then @_getArray node
        else null

  _getScalar: (node) ->
    @dropbox.readFile JsonDrop.pathFor(node, 'val.json'), (error, val) ->
      val unless error

  _getArray: (node) ->
    @dropbox.readFile JsonDrop.pathFor(node, 'array.json'), (error, val) =>
      index = JSON.parse val
      array = []
      _.each index, (item) =>
        @dropbox.readFile JsonDrop.pathFor(node, item), (error, val) -> array.push(val)
      array unless error

  _set: (node, val) ->
    @_clear node
    return @_delete(node) if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
    return @_setScalar(node, val) if _.isString(val) or _.isNumber(val) or _.isBoolean(val) or _.isDate(val) or _.isRegExp(val)
    return @_setArray(node, val) if _.isArray val
    return @_setObject(node, val) if _.isObject val

  _delete: (node) ->

  _setScalar: (node, scalar) ->
    serializedVal = JSON.stringify scalar
    @dropbox.writeFile JsonDrop.pathFor(node, 'val.json'), serializedVal, (error, stat) =>
      throw new Error(stat) if error

  _setObject: (node, obj) ->
    _.chain(obj).pairs().each ([key, value]) =>
      @_set(node.child(key), value)

  _setArray: (node, array) ->
  	idx = []
  	_.each array, (item, i) =>
      new Node(path: node.path + '/_' + i, jsonDrop: @).setVal(item)
      idx.push '_' + i
    serializedVal = JSON.stringify idx
    @dropbox.writeFile JsonDrop.pathFor(node, 'array.json'), serializedVal, (error, stat) =>
      throw new Error(stat) if error

  @normalizePath = (path) ->
    path.replace(///^/+///, '').replace(////+$///, '')

# Class representing a data endpoint
class Node
  constructor: ({@path, @jsonDrop}) ->
	   @value = null

  child: (subPath) ->
    return new Node(path: @path + '/' + JsonDrop.normalizePath(subPath), jsonDrop: @jsonDrop)

  getVal: () ->
    @value = @jsonDrop._get(@) if not @value
    return @value

  setVal: (obj) ->
    @value = obj
    @jsonDrop._set(@, obj)
    @
