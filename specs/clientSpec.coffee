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

SCALAR_FILE = 'val.json'

toAbsolute = (path) ->
 if path is ''
   ROOT_DIR
 else
   ROOT_DIR + '/' + path.replace(///^/+///, '').replace(////+$///, '')

serializeScalar = (val) ->
  JSON.stringify({val: val})

monitor = (callback) ->
  recorder = (args...) ->
    recorder.called = true
    callback args...
  recorder.called = false
  recorder

# Testing write operations
describe "Node.setVal", ->
  fsys =
     writeFile: (path, val, callback) ->
       callback()
     remove: (path, callback) ->
       callback(null, null)
  jsonDrop = new JsonDrop(fsys: fsys)
  expectWriteScalarFile = (fsys, val, path = '') ->
    serVal = serializeScalar val
    expect(fsys.writeFile).toHaveBeenCalledWith "#{toAbsolute(path)}/#{SCALAR_FILE}", serVal,
        jasmine.any(Function)
  expectWriteArray = (fsys, array,  path = '') ->
    index = '[' + (_.map array, (item, i) -> '"_' + i + '"').join(',') + ']'
    _.each array, (item, index) =>
      expectWriteScalarFile fsys, item, "_#{index}"
  expectWriteObject = (fsys, obj, path = '') ->
    deepExpect = (obj, path) ->
      _(obj).each (val, key) ->
        p = path + '/' + key
        return if _.isNaN(val) or _.isNull(val) or _.isUndefined(val) or _.isFunction(val)
        if _.isString(val) or _.isNumber(val) or _.isBoolean(val) or _.isDate(val) or _.isRegExp(val)
          return expectWriteScalarFile fsys, val, p
        if _.isArray(val)
          return expectWriteArray fsys, val, p
        deepExpect(val, p)
    deepExpect obj, path
  expectClear = (fsys, path = ROOT_DIR) ->
    expect(fsys.remove).toHaveBeenCalledWith path, jasmine.any(Function)
  testSetVal = (node, val, expectOnSet) ->
    spyOn(fsys, 'writeFile').andCallThrough()
    spyOn(fsys, 'remove').andCallThrough()
    callback = monitor (err) -> expectOnSet(fsys, val)
    node.setVal val, callback
    expectClear fsys
    expect(callback.called).toBe true
  testSetScalar = (node, val) -> testSetVal node, val, expectWriteScalarFile
  testSetArray = (node, val) -> testSetVal node, val, expectWriteArray
  testSetObject = (node, val) -> testSetVal node, val, expectWriteObject
  it "with no args should throw", ->
    expect( -> new JsonDrop().get().setVal()).toThrow()
  it "with String arg", ->
    testSetScalar jsonDrop.get(), 'A String'
  it "with Numeric arg", ->
     testSetScalar jsonDrop.get(), 12.3
  it "with Boolean arg", ->
    testSetScalar jsonDrop.get(), true
  it  "with Array arg", ->
    testSetArray jsonDrop.get(), [1,2,3]
  it  "with Object arg", ->
    obj = {x:1, y: {z: 2}, f: () ->}
    testSetObject jsonDrop.get(), obj

# Testing push operations
describe "Node.pushVal", ->
  fsys =
    writeFile: (path, val, callback) -> callback()
    remove: (path, callback) -> callback(null, null)
  jsonDrop = new JsonDrop(fsys: fsys)
  it "returns a node", ->
    node = jsonDrop.get()
    node.setVal 1, (err) ->
      node.pushVal 1, (err, child) ->
        child.getVal (err, val) ->
          expect(val).toBe 1

# Testing read operations
describe "Node.getVal", ->
  testGetVal = (node, expectOnGet) ->
    callback = monitor expectOnGet
    node.getVal callback
    expect(callback.called).toBe true

  it "returns null when node is not set", ->
    fsys =
      readdir: (path, callback) ->
        callback 'err'
    jsonDrop = new JsonDrop(fsys: fsys)
    testGetVal jsonDrop.get(), (err, val) ->
      expect(val).toBe null

  it "A scalar node returns a scalar", ->
    scalar = 'A String'
    fsys =
      readdir: (path, callback) ->
        callback(null, [SCALAR_FILE])
      readFile: (file, callback) ->
        expect(file).toBe "#{ROOT_DIR}/#{SCALAR_FILE}"
        callback null, serializeScalar(scalar)
    jsonDrop = new JsonDrop(fsys: fsys)
    testGetVal jsonDrop.get(), (err, val) ->
      expect(val).toBe scalar

  it "An array node returns an Object", ->
    array = [1, 3, 2]
    obj = _.reduce array,
      (obj, item, index) ->
        obj["_#{index}"] = item
        obj
      {}
    dirs = {'/jsondrop': _.keys(obj)}
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
    fsys =
      readdir: (path, callback) ->
        callback(null, dirs[path])
      readFile: (file, callback) =>
        expect(_.chain(files).keys().contains(file).value()).toBe true
        callback(null, files[file])
    jsonDrop = new JsonDrop(fsys: fsys)
    testGetVal jsonDrop.get(), (err, val) ->
      expect(val).toEqual obj
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

    fsys =
      readdir: (dir, callback) ->
        callback null, dirs[dir]
      readFile: (file, callback) =>
        expect(_.chain(files).keys().contains(file).value()).toBe true
        callback null, files[file]
    jsonDrop = new JsonDrop(fsys: fsys)
    testGetVal jsonDrop.get(), (err, val) ->
      expect(val).toEqual obj



# Testing JsonDrop with an in memory file system
describe "Basic CRUD", ->
  jsonDrop = JsonDrop.inMemory()
  rootNode = jsonDrop.get()
  it "Non existent nodes should have an empty object value", ->
    rootNode.getVal (err, val) ->
      expect(val).toEqual null
    rootNode.child('child').getVal (err, val) ->
      expect(val).toEqual null
  it "Parents nodes should have the values changed when children are updated", ->
    childNode = rootNode.child('child').setVal 'hello', ->
      rootNode.getVal (err, val) ->
        expect(val).toEqual {child: 'hello'}
  it "Parents nodes should have the values changed when children are updated", ->
    jsonDrop = JsonDrop.inMemory()
    rootNode = jsonDrop.get()
    rootNode.setVal {x: 1}, (err) ->
      rootNode.getVal (err, val) ->
        expect(val).toEqual {x: 1}
    childNode = rootNode.child('y')
    childNode.setVal 2, (err) ->
      rootNode.getVal (err, val) ->
        expect(val).toEqual {x:1, y: 2}
  it "Parents scalar nodes should change type when children are added", ->
     jsonDrop = JsonDrop.inMemory()
     rootNode = jsonDrop.get()
     rootNode.setVal 1, (err) ->
       rootNode.getVal (err, val) ->
         expect(val).toEqual 1
     childNode = rootNode.child('y')
     childNode.setVal 2, (err) ->
       rootNode.getVal (err, val) ->
         expect(val).toEqual {y: 2}

describe "Node iteration methods", ->
  jsonDrop = JsonDrop.inMemory()
  rootNode = jsonDrop.get()
  array = ["a", "b", "c"]
  it "Arrays should be iterated in order", ->
    rootNode.setVal array, (err) ->
      expect(err).toEqual null
      rootNode.forEach(
        (item, node, index) -> expect(item).toEqual array[index]
        (err) -> expect(err).toEqual null)
  it "Arrays should be mapped in order", ->
      rootNode.map (err, result) ->
          expect(err).toEqual null
          expect(result).toEqual array
  it "Arrays should be mapped in order", ->
    array = [{name:'a'}, {name: 'b'}]
    rootNode.setVal array, (err) ->
      expect(err).toEqual null
      rootNode.map(
        (element) -> element.name
        (err, result) ->
          expect(err).toEqual null
          expect(result).toEqual ['a', 'b'])
