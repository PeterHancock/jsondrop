if global? and require? and module?
  exports = global
  exports._ = require('underscore')
  exports.async = require('async')

# The client API
class JsonDrop

  constructor: ({fsys, key}) ->
    throw new Error 'Require a fsys or a dropbox key' unless fsys or key
    if key
      @fsys = new DropBoxAdapter(key: key)
    else
      @fsys = fsys
    @nodeManager = new NodeManager(fsys: @fsys)

  # Get the Node instance representing data at the path (or root if no path supplied)
  get: (path) ->
    @nodeManager.get path

class NodeManager

  @SCALAR_FILE = 'val.json'

  @ARRAY_FILE = 'array.json'

  @JSONDROP_DIR = '/jsondrop'

  constructor: ({@fsys}) ->

  get: (path) ->
    p = if path then NodeManager.normalizePath(path) else ''
    new Node(path: p, nodeManager: @)

  # Create the fsys path for the file at the node
  @pathFor = (node, file) ->
    filePart = if file then '/' + file else ''
    pathPart = if node.path then '/' + node.path else ''
    return @JSONDROP_DIR + pathPart + filePart

  # Create the fsys path for the scalar node
  @pathForScalar = (node) ->
    NodeManager.pathFor node, NodeManager.SCALAR_FILE

  # Create the fsys path for the scalar node
  @pathForArray = (node) ->
    NodeManager.pathFor node, NodeManager.ARRAY_FILE

  @normalizePath = (path) ->
    return path if path is ''
    path.replace(///^/+///, '').replace(////+$///, '')

  _clear: (node, callback) ->
    @fsys.remove NodeManager.pathFor(node), (error, stat) ->
      callback()

  child: (node, path) ->
    cleanPath =  NodeManager.normalizePath(path)
    childPath = if node.path then node.path + '/' + cleanPath else cleanPath
    return new Node(path: childPath, nodeManager: @)

  _get: (node, callback) ->
    @fsys.readdir NodeManager.pathFor(node), (error, entries) =>
      return callback(error, null) if error
      return @_getScalar(node, callback) if _(entries).contains NodeManager.SCALAR_FILE
      return @_getArray(node, callback) if _(entries).contains NodeManager.ARRAY_FILE
      return @_getObject(node, entries, callback)

  _getScalar: (node, callback) ->
    @fsys.readFile NodeManager.pathForScalar(node),
      (err, val) ->
        callback(err, JSON.parse(val).val)

  _getArray: (node, callback) ->
    @fsys.readFile NodeManager.pathForArray(node), (error, val) =>
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
    @fsys.writeFile NodeManager.pathForScalar(node), serializedVal,
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
        @fsys.writeFile NodeManager.pathForArray(node), idx, (err, stat) =>
          callback err

# Class representing a data endpoint
class Node
  constructor: ({@path, @nodeManager}) ->
	   @value = null

  child: (subPath) ->
    throw new Exception('No child path') if not subPath
    @nodeManager.child(@, subPath)

  getVal: (callback) ->
    if @value
      return if callback then callback(null, @value) else @value
    else
      @nodeManager._get @, (err, value) =>
        @value = value if not err
        callback err, value

  setVal: (obj, callback) ->
    @value = obj
    @nodeManager._set(@, obj, callback, true)
    @
