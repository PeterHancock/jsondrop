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
    pathPart = if node.path then '/' + node.path else ''
    return @JSONDROP_DIR + pathPart + filePart

  # Create the dropbox path for the scalar node
  @pathForScalar = (node) ->
    JsonDrop.pathFor node, JsonDrop.SCALAR_FILE

  # Create the dropbox path for the scalar node
  @pathForArray = (node) ->
    JsonDrop.pathFor node, JsonDrop.ARRAY_FILE

  @normalizePath = (path) ->
    return path if path is ''
    path.replace(///^/+///, '').replace(////+$///, '')

  _clear: (node, callback) ->
    @dropbox.remove JsonDrop.pathFor(node), (error, stat) ->
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

  _set: (node, val, callback, clear) ->
    onClear = () =>
      return @_delete(node, callback) if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
      return @_setScalar(node, val, callback) if _.isString(val) or _.isNumber(val) or _.isBoolean(val) or _.isDate(val) or _.isRegExp(val)
      return @_setArray(node, val, callback) if _.isArray val
      return @_setObject(node, val, callback) if _.isObject val
    if clear
      @_clear node, onClear
    else
      onClear()

  _delete: (node, callback) ->
    callback()

  _setScalar: (node, scalar, callback) ->
    serializedVal = JSON.stringify {val: scalar}
    @dropbox.writeFile JsonDrop.pathForScalar(node), serializedVal,
      (err, stat) -> callback err

  _setObject: (node, obj, callback) ->
    async.forEach _.chain(obj).pairs().value(),
      ([key, value], cb) =>
        @_set node.child(key), value, (err) -> cb err
      (err) -> callback err

  _setArray: (node, array, callback) ->
    i = 0
    async.reduce array, [],
      (memo, item, cb) =>
        j = i
        i = j + 1
        memo.push '_' + j
        node.child('_' + j).setVal(item, (err) -> cb(err, memo))
      (error, index) =>
        return callback(error) if error
        idx = JSON.stringify index
        @dropbox.writeFile JsonDrop.pathForArray(node), idx, (err, stat) =>
          callback err

# Class representing a data endpoint
class Node
  constructor: ({@path, @jsonDrop}) ->
	   @value = null

  child: (subPath) ->
    throw new Exception('No child path') if not subPath
    subPath =  JsonDrop.normalizePath(subPath)
    childPath = if @path then @path + '/' + subPath  else subPath 
    return new Node(path: childPath, jsonDrop: @jsonDrop)

  getVal: (callback) ->
    if @value
      return if callback then callback(null, @value) else @value
    else
      @jsonDrop._get @, (err, value) =>
        @value = value if not err
        callback err, value

  setVal: (obj, callback) ->
    @value = obj
    @jsonDrop._set(@, obj, callback, true)
    @
