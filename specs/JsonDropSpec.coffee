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

# Testing write operations
describe "Node.setVal", ->
  dropbox =
     writeFile: (path, val, callback) ->
     remove: (path, callback) ->
  jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
  spy = () ->
    spyOn(dropbox, 'writeFile')
    spyOn(dropbox, 'remove')
  expectClear = (path) ->
     expect(dropbox.remove).toHaveBeenCalledWith path, jasmine.any(Function)
  it "with no args should throw", ->
    expect( -> new JsonDrop().get().setVal()).toThrow()
  it "with String arg", ->
    spy()
    jsonDrop.get().setVal('hello')
    expectClear '/jsondrop'
    expect(dropbox.writeFile).toHaveBeenCalledWith '/jsondrop/val.json', '"hello"', jasmine.any(Function)
  it "with Numeric arg", ->
    spy()
    jsonDrop.get().setVal(12.3)
    expectClear '/jsondrop'
    expect(dropbox.writeFile).toHaveBeenCalledWith '/jsondrop/val.json', '12.3', jasmine.any(Function)
  it "with Numeric arg", ->
    spy()
    jsonDrop.get().setVal(true)
    expectClear '/jsondrop'
    expect(dropbox.writeFile).toHaveBeenCalledWith '/jsondrop/val.json', 'true', jasmine.any(Function)
  it  "with Array arg", ->
    array = [1,2,3]
    spy()
    jsonDrop.get().setVal(array)
    expectClear '/jsondrop'
    expect(dropbox.writeFile).toHaveBeenCalledWith '/jsondrop/array.json', '["_0","_1","_2"]',
        jasmine.any(Function)
    _.each array, (item, index) =>
      expect(dropbox.writeFile).toHaveBeenCalledWith '/jsondrop/_' + index + '/val.json', '' + item,
          jasmine.any(Function)
  it  "with Object arg", ->
    obj = {x:1, y: {z: 2}, f: () ->}
    spy()
    jsonDrop.get().setVal(obj)
    expectClear '/jsondrop'
    expect(dropbox.writeFile).toHaveBeenCalledWith '/jsondrop/x/val.json', '1',
        jasmine.any(Function)
    expect(dropbox.writeFile).toHaveBeenCalledWith '/jsondrop/y/z/val.json', '2',
        jasmine.any(Function)

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
        callback(null, ['val.json'])
      readFile: (file, callback) ->
        expect(file).toBe '/jsondrop/val.json'
        callback(null, 'A String')
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    expect(jsonDrop.get().getVal()).toBe('A String')
  it "An array node returns an array", ->
    array = [1, 3, 2]
    dirs = {'/jsondrop': ['array.json', '_0', '_1', '_2']}
    dirs = _.reduce array,
      (memo, item, i) ->
        memo["/jsondrop/_#{i}"] = ['val.json']
        memo
      dirs
    files = _.reduce array,
      (memo, item, i) ->
        memo["/jsondrop/_#{i}/val.json"] = item
        memo
      {}
    index = _.reduce array,
      (memo, item, i) ->
        memo.push '_' + i
        memo
      []
    files['/jsondrop/array.json'] = JSON.stringify index
    dropbox =
      readdir: (path, callback) ->
        callback(null, dirs[path])
      readFile: (file, callback) =>
        expect(_.chain(files).keys().contains(file).value()).toBe true
        callback(null, files[file])
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    expect(jsonDrop.get().getVal()).toEqual(array)
  it "An object node returns an object", ->
    obj = {x:1, y: {z: 2}}
    dirs =
      '/jsondrop': ['x', 'y']
      '/jsondrop/x': ['val.json']
      '/jsondrop/y': ['z']
      '/jsondrop/y/z': ['val.json']
    files =
      '/jsondrop/x/val.json': 1
      '/jsondrop/y/z/val.json': 2
    dropbox =
      readdir: (dir, callback) ->
        callback null, dirs[dir]
      readFile: (file, callback) =>
        expect(_.chain(files).keys().contains(file).value()).toBe true
        callback null, files[file]
    jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
    expect(jsonDrop.get().getVal()).toEqual(obj)
