if global? and require? and module?
  exports = global
  exports._ = require('underscore')
  exports.async = require('async')

# The client API
class JsonDrop

  @SCALAR_FILE = 'val.json'

  @ARRAY_FILE = 'array.json'

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

  # Create the dropbox path for the scalar node
  @pathForScalar = (node) ->
    JsonDrop.pathFor node, JsonDrop.SCALAR_FILE

  # Create the dropbox path for the scalar node
  @pathForArray = (node) ->
    JsonDrop.pathFor node, JsonDrop.ARRAY_FILE

  _clear: (node, callback) ->
    @dropbox.remove JsonDrop.pathFor(node), (error, stat) =>
      callback()

  _get: (node, callback) ->
    @dropbox.readdir JsonDrop.pathFor(node), (error, entries) =>
      return callback(error, null) if error
      return @_getScalar(node, callback) if _(entries).contains JsonDrop.SCALAR_FILE
      return @_getArray(node, callback) if _(entries).contains JsonDrop.ARRAY_FILE
      return @_getObject(node, entries, callback)

  _getScalar: (node, callback) ->
    @dropbox.readFile JsonDrop.pathForScalar(node),
      (err, val) ->
        callback(err, JSON.parse(val).val)

  _getArray: (node, callback) ->
    @dropbox.readFile JsonDrop.pathForArray(node), (error, val) =>
      return if error
      index = JSON.parse val
      async.map index,
        (item, cb) =>
          node.child(item).getVal(cb)
        (err, results) =>
          callback(err, results)

  _getObject: (node, entries, callback) ->
    async.reduce entries, {},
      (memo, file, cb) =>
        @_get(node.child(file),
          (e, val) =>
            memo[file] = val
            cb(e, memo))
      (err, memo) ->
        val = if err then null else memo
        callback err, val

  _set: (node, val) ->
    @_clear node, =>
    return @_delete(node) if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
    return @_setScalar(node, val) if _.isString(val) or _.isNumber(val) or _.isBoolean(val) or _.isDate(val) or _.isRegExp(val)
    return @_setArray(node, val) if _.isArray val
    return @_setObject(node, val) if _.isObject val

  _delete: (node) ->

  _setScalar: (node, scalar) ->
    serializedVal = JSON.stringify {val: scalar}
    @dropbox.writeFile JsonDrop.pathForScalar(node), serializedVal, (error, stat) =>
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
    @dropbox.writeFile JsonDrop.pathForArray(node), serializedVal, (error, stat) =>
      throw new Error(stat) if error

  @normalizePath = (path) ->
    path.replace(///^/+///, '').replace(////+$///, '')

# Class representing a data endpoint
class Node
  constructor: ({@path, @jsonDrop}) ->
	   @value = null

  child: (subPath) ->
    return new Node(path: @path + '/' + JsonDrop.normalizePath(subPath), jsonDrop: @jsonDrop)

  getVal: (callback) ->
    if @value
      callback null, @value
    else
      @jsonDrop._get @, (err, value) =>
        @value = value if not err
        callback err, value

  setVal: (obj) ->
    @value = obj
    @jsonDrop._set(@, obj)
    @
