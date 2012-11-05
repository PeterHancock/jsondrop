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
    @nodes = new NodeState('/')

  get: (path) ->
    path = if path then NodeManager.normalizePath(path) else ''
    new Node(path: path, nodeManager: @)

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
    @get childPath

  _getVal: (node, callback) ->
    nodeState = @_getNodeState node
    return callback(null, undefined) if not nodeState
    if nodeState.loaded
      callback null, nodeState.value
    else
      @_loadVal node, (err, val) =>
        return callback(err, null) if err
        if val
          nodeState.setVal(val)
        callback(err, val)

  _getNodeState: (node) ->
    return @nodes if not node.path
    _.reduce node.path.split('/'),
      (parent, path) ->
        return parent if parent is null
        parent.child(path)
      @nodes

  _setNodeState: (node, val) ->
    return @nodes.setVal(val) if not node.path
    nodeState = _.reduce node.path.split('/'),
      (parent, path) ->
        child = parent.child(path)
        if not child
          child = new NodeState(path, parent)
        child
      @nodes
    nodeState.setVal val

  _loadVal: (node, callback) ->
    @fsys.readdir NodeManager.pathFor(node), (error, entries) =>
      return callback(error, null) if error
      return @_getScalar(node, callback) if _(entries).contains NodeManager.SCALAR_FILE
      return @_getArray(node, callback) if _(entries).contains NodeManager.ARRAY_FILE
      return @_getObject(node, entries, callback)

  _getScalar: (node, callback) ->
    @fsys.readFile NodeManager.pathForScalar(node),
      (err, val) ->
        val = if err then null else JSON.parse(val).val
        callback err, val

  _getArray: (node, callback) ->
    @fsys.readFile NodeManager.pathForArray(node), (error, val) =>
      return if error
      index = JSON.parse val
      mapAsync  index,
        (item, cb) =>
          node.child(item).getVal(cb)
        callback

  _getObject: (node, entries, callback) ->
    reduceAsync entries, null,
      (memo, file, callback) =>
        @_getVal node.child(file), (err, val) =>
          memo = if memo then memo else {}
          memo[file] = val
          callback err, memo
      callback


  _setNewVal: (node, val, callback) ->
    @_clear node, =>
      @_setVal node, val, (err) =>
        return callback(err) if err
        @_setNodeState node, val
        callback(err)

  _setVal: (node, val, callback) ->
    return @_delete(node, callback) if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
    return @_setScalar(node, val, callback) if _.isString(val) or _.isNumber(val) or _.isBoolean(val) or _.isDate(val) or _.isRegExp(val)
    return @_setArray(node, val, callback) if _.isArray val
    return @_setObject(node, val, callback) if _.isObject val


  _delete: (node, callback) ->
    callback()

  _setScalar: (node, scalar, callback) ->
    serializedVal = JSON.stringify {val: scalar}
    @fsys.writeFile NodeManager.pathForScalar(node), serializedVal, callback

  _setObject: (node, obj, callback) ->
    forEachAsync _.chain(obj).pairs().value(),
      ([key, value], callback) =>
        @_setVal node.child(key), value, callback
      callback

  _setArray: (node, array, callback) ->
    i = 0
    reduceAsync array, [],
      (memo, item, cb) =>
        j = i
        i = j + 1
        memo.push '_' + j
        @_setVal(node.child('_' + j), item, (err) -> cb(err, memo))
      (error, index) =>
        return callback(error) if error
        idx = JSON.stringify index
        @fsys.writeFile NodeManager.pathForArray(node), idx, callback

# Class representing a data endpoint
class Node
  constructor: ({@path, @nodeManager}) ->

  child: (subPath) ->
    throw new Exception('No child path') if not subPath
    @nodeManager.child(@, subPath)

  getVal: (callback) ->
      @nodeManager._getVal @, callback

  setVal: (obj, callback) ->
    @nodeManager._setNewVal(@, obj, callback)
    @

 class NodeState
  constructor: (@path, parent, val) ->
    @parent = if parent then parent else null
    if @parent
      @parent.children[@path] = @
    @loaded = false
    @value = undefined
    if val
      @loaded = true
      @value = val
    @children = {}

  setVal: (val) ->
    @loaded = true
    @value = val
    @_updateParentVal(val)

  _updateParentVal: (val) ->
    if @parent
      if @parent.value
        @parent.value[@path] = val
      else
        parentVal = {}
        parentVal[@path] = val
        @parent._updateParentVal(parentVal)

  child: (path) ->
    child = @children[path]
    return child if child
    if @loaded
      val = @value[path]
      if val
        child = new NodeState(path, @, val)
      else
        child = null
    else
      child = new NodeState(path, @parent)
    child

reduceAsync = async.reduce

forEachAsync = async.forEach

mapAsync = async.map
