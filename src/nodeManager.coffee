if global? and require? and module?
  exports = global
  exports._ = require('underscore')

# An internal class used for transforming, caching and syncronizing data with the File System
class NodeManager

  @NODE_VAL_FILE = 'val.json'

  @JSONDROP_DIR = '/jsondrop'

  @eachAsync = (arr, iterator, callback) ->
    complete = _.after arr.length, callback
    _.each arr, (item, index) ->
      iterator item, index, (err) ->
        if err
          callback(err)
          callback = () ->
        else
          complete()

  constructor: ({@fsys}) ->

  # Create the fsys path for the file at the node
  @pathForNode = (node, file) ->
    filePart = if file then '/' + file else ''
    pathPart = if node.path then '/' + node.path else ''
    return @JSONDROP_DIR + pathPart + filePart

  # Create the fsys path for the node val file
  @pathForNodeValFile = (node) ->
    NodeManager.pathForNode node, NodeManager.NODE_VAL_FILE

  getVal: (node, callback) ->
    @_readVal node, (err, val) =>
      return callback(err, null) if err
      callback(err, val)

  each: (node, iterator, callback) ->
    @fsys.readdir NodeManager.pathForNode(node), (error, entries) =>
      NodeManager.eachAsync entries,
        (dir, index, callback) =>
          if /^-.*/.test(dir)
            child = node.child(dir)
            @getVal child,
              (err, val) ->
                if err
                  return callback err
                else
                  iterator val, child, index
                  return callback()
          else
            callback()
        callback

  setVal: (node, val, callback) ->
    @_writeVal node, val, (err) =>
      return callback(err)

  remove: (node, callback) ->
    @_clearNodeVal node, () ->
      @_clearNodeArray(node, callback)

  pushVal: (node, obj, callback) ->
    child = node.child NodeManager.createIndex()
    child.setVal obj, (err) -> callback err, child

  _readVal: (node, callback) ->
    @fsys.readdir NodeManager.pathForNode(node), (error, entries) =>
      return callback(error, null) if error
      return @_readScalar(node, callback) if _(entries).contains NodeManager.NODE_VAL_FILE
      return callback null, null

  _clearNodeVal: (node, callback) ->
    @fsys.remove NodeManager.pathForNodeValFile(node), (error, stat) ->
      callback()
  
  _clearNodeArray: (node, callback) ->
    NodeManager.eachAsync entries,
      (dir, index, callback) =>
        if /^-.*/.test(dir)
          @fsys.remove NodeManager.pathForNode(node, dir), (err, stat) ->
            return callback()
        else
          return callback()
      callback

  _readScalar: (node, callback) ->
    @fsys.readFile NodeManager.pathForNodeValFile(node),
      (err, val) =>
        val = if err then null else @_readFile(val).val
        callback err, val

  _readFile: (text) ->
    if _.isObject(text) then text else JSON.parse(text)

  _writeVal: (node, val, callback) ->
    return callback(null) if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
    serializedVal = JSON.stringify {val: val}
    return @fsys.writeFile NodeManager.pathForNodeValFile(node), serializedVal, callback

  @createIndex = (() ->
    counter = -1
    () ->
      counter = counter + 1
      "-#{new Date().getTime().toString(36)}-#{counter}")()
