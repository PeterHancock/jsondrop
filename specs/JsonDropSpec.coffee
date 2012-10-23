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
  serVal = serializeScalar val
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

serializeScalar = (val) ->
  JSON.stringify({val: val})

testAsync = (run, expectation) ->
  ready = false
  rtn = null
  runs ->
    run (err, val) ->
      rtn = val
      ready = true
  waitsFor (-> ready), '', 100
  runs ->
    expectation rtn

testAsyncSet = (run, expectation) ->
  ready = false
  runs ->
    run (err) ->
      ready = true
  waitsFor (-> ready), '', 100
  runs ->
    expectation()

# Testing write operations
describe "Node.setVal", ->
  dropbox =
     writeFile: (path, val, callback) ->
       callback()
     remove: (path, callback) ->
       callback(null, null)
  jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
  spy = () ->
    spyOn(dropbox, 'writeFile').andCallThrough()
    spyOn(dropbox, 'remove').andCallThrough()
  testSet = (val, valExpect) ->
    spy()
    run = (callback) -> jsonDrop.get().setVal(val, callback)
    expectation = () ->
     expectClear dropbox
     valExpect dropbox, val
    testAsync run, expectation
  testSetScalar = (val) -> testSet val, expectScalar
  testSetArray = (val) -> testSet val, expectArray
  it "with no args should throw", ->
    expect( -> new JsonDrop().get().setVal()).toThrow()
  it "with String arg", ->
    testSetScalar 'A String'
  it "with Numeric arg", ->
     testSetScalar 12.3
  it "with Boolean arg", ->
    testSetScalar true
  it  "with Array arg", ->
    testSetArray [1,2,3]
  it  "with Object arg", ->
    obj = {x:1, y: {z: 2}, f: () ->}
    spy()
    run = (callback) -> jsonDrop.get().setVal(obj, callback)
    expectation = () ->
      expectClear dropbox
      expectScalar dropbox, 1, "x"
      expectScalar dropbox, 2, "y/z"
    testAsync run, expectation

# Testing read operations
describe "Node.getVal", ->
  it "returns null when node is not set", ->
    dropbox =
      readdir: (path, callback) ->
        callback 1
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    run = (callback) -> jsonDrop.get().getVal callback
    expectation = (val) -> expect(val).toBe null
    testAsync run, expectation

  it "A scalar node returns a scalar", ->
    scalar = 'A String'
    dropbox =
      readdir: (path, callback) ->
        callback(null, [SCALAR_FILE])
      readFile: (file, callback) ->
        expect(file).toBe "#{ROOT_DIR}/#{SCALAR_FILE}"
        callback null, serializeScalar(scalar)
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    run = (callback) -> jsonDrop.get().getVal callback
    expectation = (val) -> expect(val).toBe scalar
    testAsync run, expectation

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
        memo["#{ROOT_DIR}/_#{i}/#{SCALAR_FILE}"] = serializeScalar(item)
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
    run = (callback) -> jsonDrop.get().getVal callback
    expectation = (val) -> expect(val).toEqual array
    testAsync run, expectation
  it "An object node returns an object", ->
    toDirectoryStructure = (obj, dirs = {}, files = {}, path = ROOT_DIR) ->
      dirs[path] = _.reduce obj,
        (memo, v, k) ->
          memo.push k
          if _.isObject(v)
            toDirectoryStructure v, dirs, files, "#{path}/#{k}"
          else
            dirs["#{path}/#{k}"] = [SCALAR_FILE]
            files["#{path}/#{k}/#{SCALAR_FILE}"] = serializeScalar(v)
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
    run = (callback) -> jsonDrop.get().getVal callback
    expectation = (val) ->
      expect(val).toEqual obj
    testAsync run, expectation
