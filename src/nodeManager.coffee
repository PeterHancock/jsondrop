if global? and require? and module?
  exports = global
  exports._ = require('underscore')

# An internal class used for transforming, caching and syncronizing data with the File System
class NodeManager

  @NODE_VAL_FILE = 'val.json'

  @JSONDROP_DIR = '/jsondrop'

  @JSONDROP_DATA = "#{NodeManager.JSONDROP_DIR}/data"

  constructor: ({@fsys}) ->
    #TODO Check database compatability

  @isArrayNodeElement = (name) ->
    /^_.*/.test(name)

  # Create the fsys path for the file at the node
  @pathForNode = (node, file) ->
    filePart = if file then '/' + file else ''
    pathPart = if node.path then '/' + node.path else ''
    return @JSONDROP_DATA + pathPart + filePart

  # Create the fsys path for the node val file
  @pathForNodeValFile = (node) ->
    NodeManager.pathForNode node, NodeManager.NODE_VAL_FILE

  getVal: (node, callback) ->
    @_readVal node, (err, val) =>
      return callback(err, null) if err
      callback(err, val)

  each: (node, iterator, callback) ->
    @fsys.readdir NodeManager.pathForNode(node), (error, entries) =>
      Collections.eachAsync entries,
        (dir, index, callback) =>
          if NodeManager.isArrayNodeElement dir
            child = node.child(dir)
            @getVal child,
              (err, val) ->
                return callback(err) if err
                iterator val, child, index
                return callback()
          else
            callback()
        callback

  eachSeries: (node, iterator, callback) ->
    emit = (()->
      files = {}
      index = 0
      next = () ->
        if _.has(files, index)
          [val, child] = files[index]
          files[index] = null
          if val
            iterator val, child, index
          index = index + 1
          _.defer next
      (i, val, child)->
        files[i] = [val, child]
        next()
      )()
    @fsys.readdir NodeManager.pathForNode(node), (error, entries) =>
      Collections.eachAsync entries,
        (dir, index, callback) =>
          if NodeManager.isArrayNodeElement dir
            child = node.child(dir)
            @getVal child,
              (err, val) ->
                return callback(err) if err
                emit index, val, child
                return callback()
          else
            emit index
            callback()
        callback

  setVal: (node, val, callback) ->
    @_writeVal node, val, (err) =>
      return callback(err)

  remove: (node, callback) ->
    @_removeNodeVal node, () =>
      @_removeNodeArray(node, callback)

  pushVal: (node, obj, callback) ->
    child = node.child NodeManager.createIndex()
    @setVal child, obj, (err) -> callback err, child

  _readVal: (node, callback) ->
    @fsys.readdir NodeManager.pathForNode(node), (error, entries) =>
      return callback(error, null) if error
      return @_readScalar(node, callback) if _(entries).contains NodeManager.NODE_VAL_FILE
      return callback null, null

  _removeNodeVal: (node, callback) ->
    @fsys.remove NodeManager.pathForNodeValFile(node), (error, stat) ->
      callback()
  
  _removeNodeArray: (node, callback) ->
    hasChildren = false
    @fsys.readdir NodeManager.pathForNode(node), (error, entries) =>
      Collections.eachAsync entries,
        (dir, index, callback) =>
          if /^_.*/.test(dir)
            @fsys.remove NodeManager.pathForNode(node, dir), (err, stat) ->
              return callback()
          else
            hasChildren = true
            return callback()
        () =>
          if hasChildren
            return callback()
          else
            @fsys.remove NodeManager.pathForNode(node), () ->
              return callback()

  _readScalar: (node, callback) ->
    @fsys.readFile NodeManager.pathForNodeValFile(node),
      (err, val) =>
        val = if err then null else NodeManager.parseFile(val).val
        callback err, val

  @parseFile = (text) ->
    if _.isObject(text) then text else JSON.parse(text)

  _writeVal: (node, val, callback) ->
    return callback(null) if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
    serializedVal = JSON.stringify {val: val}
    return @fsys.writeFile NodeManager.pathForNodeValFile(node), serializedVal, callback

  @createIndex = (() ->
    counter = -1
    () ->
      counter = counter + 1
      "_#{new Date().getTime().toString(36)}-#{counter}")()
