# Import jsondrop for testing with Node.js
if global? and require? and module?
  exports = global
  exports.JsonDrop =  require '../build/jsondrop'
  exports._ = require("underscore")

mockDropboxAdapter = (dropbox = null) ->
  return {getDropbox:() -> dropbox}

# Tests for the client API
# The constructor
describe "The constructor", ->
  dropbox = {api: "API Call"}
  dropboxAdapter = null
  beforeEach ->
    dropboxAdapter = {getDropbox:() -> dropbox}
  it "should throw if no dropbox supplied", ->
    expect( -> new JsonDrop()).toThrow()
  it "should expose the dropbox instance as a property", ->
    expect(new JsonDrop(dropboxAdapter: dropboxAdapter).getDropbox()).toBe dropbox

# Testing read operations
describe "The get method", ->
  jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter())
  it "with no args returns the root node", ->
    rootNode = jsonDrop.get()
    expect(rootNode.path).toBe ""
  it "with string returns the node for that path", ->
    node = jsonDrop.get('path/to/node/')
    expect(node.path).toBe "path/to/node"
    node = jsonDrop.get('/path/to/node')
    expect(node.path).toBe "path/to/node"
    node = jsonDrop.get('///path/to/node///')
    expect(node.path).toBe "path/to/node"

describe "Node.child()", ->
  it "should generate child nodes", ->
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter())
    node = jsonDrop.get('path/to/node/')
    expect(node.child('path/to/child').path).toBe 'path/to/node/path/to/child'

ROOT_DIR = '/jsondrop'

SCALAR_FILE = 'val.json'

ARRAY_FILE = 'array.json'

toAbsolute = (path) ->
 if path is ''
   ROOT_DIR
 else
   ROOT_DIR + '/' + path.replace(///^/+///, '').replace(////+$///, '')

expectScalar = (dropbox, val, path = '') ->
  serVal = JSON.stringify val
  expect(dropbox.writeFile).toHaveBeenCalledWith "#{toAbsolute(path)}/#{SCALAR_FILE}", serVal,
      jasmine.any(Function)

expectArray = (dropbox, array,  path = '') ->
  index = '[' + (_.map array, (item, i) -> '"_' + i + '"').join(',') + ']'
  expect(dropbox.writeFile).toHaveBeenCalledWith "#{toAbsolute(path)}/#{ARRAY_FILE}", index,
      jasmine.any(Function)
  _.each array, (item, index) =>
    expectScalar dropbox, item, "_#{index}"

expectClear = (dropbox, path = ROOT_DIR) ->
  expect(dropbox.remove).toHaveBeenCalledWith path, jasmine.any(Function)

# Testing write operations
describe "Node.setVal", ->
  dropbox =
     writeFile: (path, val, callback) ->
     remove: (path, callback) ->
  jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
  spy = () ->
    spyOn(dropbox, 'writeFile')
    spyOn(dropbox, 'remove')
  it "with no args should throw", ->
    expect( -> new JsonDrop().get().setVal()).toThrow()
  it "with String arg", ->
    str = 'A String'
    spy()
    jsonDrop.get().setVal str
    expectClear dropbox
    expectScalar dropbox, str
  it "with Numeric arg", ->
    num = 12.3
    spy()
    jsonDrop.get().setVal num
    expectClear dropbox
    expectScalar dropbox, num
  it "with Numeric arg", ->
    bool = true
    spy()
    jsonDrop.get().setVal bool
    expectClear dropbox
    expectScalar dropbox, bool
  it  "with Array arg", ->
    array = [1,2,3]
    spy()
    jsonDrop.get().setVal(array)
    expectClear dropbox
    expectArray dropbox, array
  it  "with Object arg", ->
    obj = {x:1, y: {z: 2}, f: () ->}
    spy()
    jsonDrop.get().setVal(obj)
    expectClear dropbox
    expectScalar dropbox, 1, "x"
    expectScalar dropbox, 2, "y/z"

# Testing read operations
describe "Node.getVal", ->
  it "returns null when node is not set", ->
    dropbox =
      readdir: (path, callback) ->
        callback 1
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    expect(jsonDrop.get().getVal()).toBe(null)
  it "A scalar node returns a scalar", ->
    dropbox =
      readdir: (path, callback) ->
        callback(null, [SCALAR_FILE])
      readFile: (file, callback) ->
        expect(file).toBe "#{ROOT_DIR}/#{SCALAR_FILE}"
        callback(null, 'A String')
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    expect(jsonDrop.get().getVal()).toBe('A String')
  it "An array node returns an array", ->
    array = [1, 3, 2]
    dirs = {'/jsondrop': [ARRAY_FILE, '_0', '_1', '_2']}
    dirs = _.reduce array,
      (memo, item, i) ->
        memo["#{ROOT_DIR}/_#{i}"] = [SCALAR_FILE]
        memo
      dirs
    files = _.reduce array,
      (memo, item, i) ->
        memo["#{ROOT_DIR}/_#{i}/#{SCALAR_FILE}"] = item
        memo
      {}
    index = _.reduce array,
      (memo, item, i) ->
        memo.push '_' + i
        memo
      []
    files["#{ROOT_DIR}/#{ARRAY_FILE}"] = JSON.stringify index
    dropbox =
      readdir: (path, callback) ->
        callback(null, dirs[path])
      readFile: (file, callback) =>
        expect(_.chain(files).keys().contains(file).value()).toBe true
        callback(null, files[file])
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    expect(jsonDrop.get().getVal()).toEqual(array)
  it "An object node returns an object", ->
    toDirectoryStructure = (obj, dirs = {}, files = {}, path = ROOT_DIR) ->
      dirs[path] = _.reduce obj,
        (memo, v, k) ->
          memo.push k
          if _.isObject(v)
            toDirectoryStructure v, dirs, files, "#{path}/#{k}"
          else
            dirs["#{path}/#{k}"] = [SCALAR_FILE]
            files["#{path}/#{k}/#{SCALAR_FILE}"] = v
          memo
        []
      [dirs, files]

    obj =
      x: 1
      y:
        z: 2

    [dirs, files] = toDirectoryStructure obj

    dropbox =
      readdir: (dir, callback) ->
        callback null, dirs[dir]
      readFile: (file, callback) =>
        expect(_.chain(files).keys().contains(file).value()).toBe true
        callback null, files[file]
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    expect(jsonDrop.get().getVal()).toEqual(obj)
