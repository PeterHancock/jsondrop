if global? and require? and module?
  exports = global
  exports._ = require('underscore')

# The client API
class JsonDrop

  constructor: ({fsys, key}) ->
    throw new Error 'Require a fsys or a dropbox key' unless fsys or key
    if key
      @fsys = new DropBoxFileSystem(key: key)
    else
      @fsys = fsys
    @nodeManager = new NodeManager(fsys: @fsys)

  # Get the Node instance representing data at the path (or root if no path supplied)
  get: (path) ->
    Node.create path, @nodeManager

# Class representing a data endpoint
class Node

  @normalizePath = (path) ->
    return path if path is ''
    path.replace(///^/+///, '').replace(////+$///, '')

  @create = (path, nodeManager) ->
    path = if path then Node.normalizePath(path) else ''
    new Node(path: path, nodeManager: nodeManager)

  constructor: ({@path, @nodeManager}) ->

  child: (path) ->
    throw new Exception('No child path') if not path
    path = Node.normalizePath(path)
    path = if @path then @path + '/' + path else path
    Node.create(path, @nodeManager)

  getVal: (callback) ->
    @nodeManager._getVal @, callback

  setVal: (obj, callback) ->
    @nodeManager._setNewVal(@, obj, callback)
    @
