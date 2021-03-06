if global? and require? and module?
  exports = global
  exports._ = require('underscore')

# The client API
class JsonDrop

  constructor: ({fsys}) ->
    throw new Error("No FSYS") unless fsys
    @fsys = fsys
    @nodeManager = new NodeManager(fsys: @fsys)

  # Get the Node instance representing data at the path (or root if no path supplied)
  get: (path) ->
    Node.create path, @nodeManager

JsonDrop.forDropbox = (dropbox) ->
    new JsonDrop(fsys: new DropBoxFileSystem(dropbox))

# Class representing a data endpoint
class Node extends Mixin
  @mixin Iterable

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

  get: (callback) ->
    @nodeManager.getVal @, callback
    @

  set: (obj, callback) ->
    @nodeManager.setVal(@, obj, callback)
    @

  remove: (callback) ->
    @nodeManager.remove(@, callback)
    @

  push: (obj, callback) ->
    @nodeManager.pushVal(@, obj, callback)
    @

  pushAll: (array..., callback) ->
    children = []
    onComplete = (err) ->
      if err
        #TODO If remove all fails should return children that were not removed
        Collections.eachAsync children,
          (child, index, callback) ->
            child.remove (e) ->
              callback "Remove all error: #{e}" if e
              callback()
          (e) ->
            if e
              callback  "#{e}\nRemove all rollback due to pushAll error: #{err}"
            else
              callback  "pushAll error: #{err}"
      else
        callback null, children
    Collections.eachSeries array,
      (val, index, callback) =>
        @push val, (err, child) ->
          return callback(err) if err
          children.push child
          callback()
      onComplete
    @

  # Implement Iterable
  each: (iterator, callback) ->
    @nodeManager.each @, iterator, callback
    @

  # Implement Iterable
  eachSeries: (iterator, callback) ->
    @nodeManager.eachSeries @, iterator, callback
    @
