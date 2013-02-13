# The DropBox adapter
class InMemoryFileSystem

  constructor: () ->
    @dirs = {}

  remove: (path, callback) ->
    [root, parents..., file] = path.split('/')
    parent = @_getDir parents
    delete parent[file]
    callback()

  readdir: (path, callback) ->
    [root, paths...] = path.split('/')
    dir = @_getDir(paths)
    dir = if dir then _.keys(dir) else []
    callback null, dir

  readFile: (path, callback) ->
    [root, paths..., file] = path.split('/')
    dir = @_getDir(paths)
    text = if dir then dir[file] else null
    callback null, text

  writeFile: (path, text, callback) ->
    [root, paths..., file] = path.split('/')
    @_mkdir(paths)[file] = text
    callback()


  _getDir: (paths) ->
    _.reduce paths,
      (memo, path) ->
        next = if memo then memo[path] else null
        if next then next else null
      @dirs

  _mkdir: (paths) ->
    _.reduce paths,
      (memo, part) ->
        next = memo[part]
        if not next
          next  = {}
          memo[part] = next
        next
      @dirs

JsonDrop.InMemory = InMemoryFileSystem

JsonDrop.inMemory = () ->
  new JsonDrop(fsys: new InMemoryFileSystem())
