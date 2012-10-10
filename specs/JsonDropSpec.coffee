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
