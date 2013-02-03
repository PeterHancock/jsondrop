if global? and require? and module?
  exports = global
  exports._ = require('underscore')

# An internal class used for transforming, caching and syncronizing data with the File System
class NodeManager

  @SCALAR_FILE = 'val.json'

  @ARRAY_FILE = 'array.json'

  @JSONDROP_DIR = '/jsondrop'

  constructor: ({@fsys}) ->
    @rootNodeData = new NodeData('/')

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

  getVal: (node, callback) ->
    nodeData = @_getNodeData node
    return callback(null, undefined) if not nodeData
    if nodeData.loaded
      callback null, nodeData.value
    else
      @_readVal node, (err, val) =>
        return callback(err, null) if err
        if val
          nodeData.setVal(val)
        callback(err, val)

  setVal: (node, val, callback) ->
    @_clear node, =>
      @_writeVal node, val, (err) =>
        return callback(err) if err
        @_setNodeData node, val
        callback(err)

  remove: (node, callback) ->
    @_clear(node,callback)

  pushVal: (node, obj, callback) ->
    child = node.child NodeManager.createIndex()
    child.setVal obj, (err) -> callback err, child

  _getNodeData: (node) ->
    @_getNodeDataWithDefault(node, (path, parent) -> null)

  _setNodeData: (node, val) ->
    @_getNodeDataWithDefault(node).setVal(val)

  _getNodeDataWithDefault: (node, nodeCreator = (path, parent) -> new NodeData(path, parent)) ->
    return @rootNodeData if not node.path
    _.reduce node.path.split('/'),
      (parent, path) ->
        child = parent.child(path)
        return if child then child else nodeCreator(path, parent)
      @rootNodeData

  _readVal: (node, callback) ->
    @fsys.readdir NodeManager.pathFor(node), (error, entries) =>
      return callback(error, null) if error
      return @_readScalar(node, callback) if _(entries).contains NodeManager.SCALAR_FILE
      return @_readObject(node, entries, callback)

  _clear: (node, callback) ->
    @fsys.remove NodeManager.pathFor(node), (error, stat) ->
      callback()

  _readScalar: (node, callback) ->
    @fsys.readFile NodeManager.pathForScalar(node),
      (err, val) =>
        val = if err then null else @_readFile(val).val
        callback err, val

  _readFile: (text) ->
    if _.isObject(text) then text else JSON.parse(text)

  _readObject: (node, entries, callback) ->
    reduceAsync entries, null,
      (memo, file, callback) =>
        @getVal node.child(file), (err, val) =>
          memo = if memo then memo else {}
          memo[file] = val
          callback err, memo
      callback

  _writeVal: (node, val, callback) ->
    return callback(null) if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
    return @_writeScalar(node, val, callback) if _.isString(val) or _.isNumber(val) or _.isBoolean(val) or _.isDate(val) or _.isRegExp(val)
    return @_writeArray(node, val, callback) if _.isArray val
    return @_writeObject(node, val, callback) if _.isObject val

  _writeScalar: (node, scalar, callback) ->
    serializedVal = JSON.stringify {val: scalar}
    @fsys.writeFile NodeManager.pathForScalar(node), serializedVal, callback

  _writeObject: (node, obj, callback) ->
    forEachAsync _(obj).pairs(),
      ([key, value], callback) =>
        @_writeVal node.child(key), value, callback
      callback

  _writeArray: (node, array, callback) ->
    reduceAsync array, 0,
      (i, item, callback) =>
        @_writeVal(node.child('_' + i), item, (error) -> callback(error, i + 1))
      (error, index) => callback(error)

  @createIndex = () ->
    "-#{new Date().getTime().toString(36)}"

 class NodeData
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
    @children = {}
    @value = val
    @_updateParentVal(val)

  _updateParentVal: (val) ->
    if @parent
      if _.isObject @parent.value
        @parent.value[@path] = val
      else
        parentVal = {}
        parentVal[@path] = val
        @parent.value = parentVal
        @parent._updateParentVal(parentVal)

  child: (path) ->
    child = @children[path]
    return child if child
    if @loaded
      val = @value[path]
      if val
        child = new NodeData(path, @, val)
      else
        child = null
    else
      child = new NodeData(path, @parent)
    child