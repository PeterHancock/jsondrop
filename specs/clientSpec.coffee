# Import jsondrop for testing with Node.js
if global? and require? and module?
  exports = global
  exports.JsonDrop =  require '../build/jsondrop'
  exports._ = require("underscore")


# Tests for the client API
# The constructor
describe "The constructor", ->
  it "should throw if no fsys supplied", ->
    expect( -> new JsonDrop()).toThrow()

# Testing read operations
describe "The get method", ->
  jsonDrop = new JsonDrop(fsys: {})
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
    jsonDrop = new JsonDrop(fsys: {})
    node = jsonDrop.get('path/to/node/')
    expect(node.child('path/to/child').path).toBe 'path/to/node/path/to/child'

ROOT_DIR = '/jsondrop'

NODE_VAL_FILE = 'val.json'

toAbsolute = (path) ->
 if path is ''
   ROOT_DIR
 else
   ROOT_DIR + '/' + path.replace(///^/+///, '').replace(////+$///, '')

serializeScalar = (val) ->
  JSON.stringify({val: val})

expectCallback = (action, callback) ->
  monitoredCallback = (args...) ->
    monitoredCallback.called = true
    callback args...
  action monitoredCallback
  expect(monitoredCallback.called).toBe true

# Testing write operations
describe "Node.setVal", ->
  fsys =
     writeFile: (path, val, callback) ->
       callback()
     remove: (path, callback) ->
       callback(null, null)
  jsonDrop = new JsonDrop(fsys: fsys)
  testSetVal = (node, val, expectOnSet) ->
    spyOn(fsys, 'writeFile').andCallThrough()
    spyOn(fsys, 'remove').andCallThrough()
    expectCallback _.bind(node.setVal, node, val), (err) ->
      serVal = serializeScalar val
      expect(fsys.writeFile).toHaveBeenCalledWith "#{toAbsolute(node.path)}/#{NODE_VAL_FILE}", serVal,
          jasmine.any(Function)
  it "with no args should throw", ->
    expect( -> new JsonDrop().get().setVal()).toThrow()
  it "with String arg", ->
    testSetVal jsonDrop.get(), 'A String'
  it "with Numeric arg", ->
     testSetVal jsonDrop.get(), 12.3
  it "with Boolean arg", ->
    testSetVal jsonDrop.get(), true
  it  "with Array arg", ->
    testSetVal jsonDrop.get(), [1,2,3]
  it  "with Object arg", ->
    obj = {x:1, y: {z: 2}, f: () ->}
    testSetVal jsonDrop.get(), obj

# Testing push operations
describe "Node.pushVal", ->
  jsonDrop = JsonDrop.inMemory()
  it "returns a node", ->
    node = jsonDrop.get()
    node.pushVal 1, (err, child) ->
      child.getVal (err, val) ->
        expect(val).toBe 1

# Testing read operations
describe "Node.getVal", ->
  callGet = (node, val) ->
    expectCallback _.bind(node.getVal, node), (err, v) ->
      expect(v).toEqual val
  it "returns null when node is not set", ->
    fsys =
      readdir: (path, callback) ->
        callback 'err'
    jsonDrop = new JsonDrop(fsys: fsys)
    callGet(jsonDrop.get(), null)
  testGet = (val) ->
    fsys =
      readdir: (path, callback) ->
        callback(null, [NODE_VAL_FILE])
      readFile: (file, callback) ->
        expect(file).toBe "#{ROOT_DIR}/#{NODE_VAL_FILE}"
        callback null, serializeScalar(val)
    jsonDrop = new JsonDrop(fsys: fsys)
    callGet(jsonDrop.get(), val)
  it "A scalar node returns a scalar", ->
    testGet 'A String'
  it "An Array node returns an Array", ->
    testGet [1, 3, 2]
  it "An Object node returns an Object", ->
    obj =
      x: 1
      y:
        z: 2
    testGet obj

# Testing remove operations
describe "Node.remove", ->
  it "with no children", ->
    fsys =
      readdir: (path, callback) ->
       callback(null, [])
      remove: (path, callback) ->
       callback(null, null)
    jsonDrop = new JsonDrop(fsys: fsys)
    spyOn(fsys, 'readdir').andCallThrough()
    spyOn(fsys, 'remove').andCallThrough()
    node = jsonDrop.get('node')
    expectCallback _.bind(node.remove, node), (err) ->
      expect(fsys.remove).toHaveBeenCalledWith toAbsolute(node.path), jasmine.any(Function)
  it "with children", ->
    fsys =
      readdir: (path, callback) ->
       callback(null, ['child'])
      remove: (path, callback) ->
       callback(null, null)
    jsonDrop = new JsonDrop(fsys: fsys)
    spyOn(fsys, 'readdir').andCallThrough()
    spyOn(fsys, 'remove').andCallThrough()
    node = jsonDrop.get('node')
    expectCallback _.bind(node.remove, node), (err) ->
      expect(fsys.remove).wasNotCalledWith toAbsolute(node.path), jasmine.any(Function)

# Testing JsonDrop with an in memory file system
describe "Basic CRUD", ->
  jsonDrop = JsonDrop.inMemory()
  rootNode = jsonDrop.get()
  it "Non existent nodes should have an empty object value", ->
    rootNode.getVal (err, val) ->
      expect(val).toEqual null
    rootNode.child('child').getVal (err, val) ->
      expect(val).toEqual null
  it "Parents nodes should NOT have the values changed when children are updated", ->
    childNode = rootNode.child('child').setVal 'hello', ->
      rootNode.getVal (err, val) ->
        expect(val).toEqual null
  it "Parents nodes should have the values changed when children are updated", ->
    jsonDrop = JsonDrop.inMemory()
    rootNode = jsonDrop.get()
    rootNode.setVal {x: 1}, (err) ->
      rootNode.getVal (err, val) ->
        expect(val).toEqual {x: 1}
    childNode = rootNode.child('y')
    childNode.setVal 2, (err) ->
      rootNode.getVal (err, val) ->
        expect(val).toEqual {x:1}
  it "Parents scalar nodes should change type when children are added", ->
     jsonDrop = JsonDrop.inMemory()
     rootNode = jsonDrop.get()
     rootNode.setVal 1, (err) ->
       rootNode.getVal (err, val) ->
         expect(val).toEqual 1
     childNode = rootNode.child('y')
     childNode.setVal 2, (err) ->
       rootNode.getVal (err, val) ->
         expect(val).toEqual 1

describe "Node iteration methods", ->
  jsonDrop = JsonDrop.inMemory()
  rootNode = jsonDrop.get()
  array = ["a", "b", "c"]
  _(array).each (val) ->
    rootNode.pushVal val, (err) ->
  it "Arrays should be iterated in order", ->
    rootNode.forEach(
        (item, node, index) -> expect(item).toEqual array[index]
        (err) -> expect(err).toEqual null)
  describe "Map", ->
    it "Arrays should be mapped in order", ->
        rootNode.map (err, result) ->
            expect(err).toEqual null
            expect(result).toEqual array
    it "Arrays should be mapped in order", ->
      jsonDrop = JsonDrop.inMemory()
      rootNode = jsonDrop.get()
      array = [{name:'a'}, {name: 'b'}]
      _(array).each (val) ->
        rootNode.pushVal val, (err) ->
      rootNode.map(
        (element) -> element.name
        (err, result) ->
          expect(err).toEqual null
          expect(result).toEqual ['a', 'b'])
