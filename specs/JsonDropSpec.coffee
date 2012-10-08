# Import jsondrop for testing with Node.js
if global? and require? and module?
  exports = global
  exports.JsonDrop =  require '../build/jsondrop'


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
  dropbox = {writeFile: (path, val, errorCallback) -> }
  jsonDrop = new JsonDrop(dropboxAdapter: mockDropboxAdapter(dropbox))
  it "with no args should throw", ->
    expect( -> new JsonDrop().get().setVal()).toThrow()
  it "with String arg", ->
    spyOn(dropbox, 'writeFile')
    jsonDrop.get().setVal('hello')
    expect(dropbox.writeFile).toHaveBeenCalledWith('/jsondrop/val.json', '"hello"',
        dropbox.writeFile.mostRecentCall.args[2] # Don't care about callback
    )
  it "with Numeric arg", ->
    spyOn(dropbox, 'writeFile')
    jsonDrop.get().setVal(12.3)
    expect(dropbox.writeFile).toHaveBeenCalledWith('/jsondrop/val.json', '12.3',
        dropbox.writeFile.mostRecentCall.args[2] # Don't care about callback
    )
  it "with Numeric arg", ->
    spyOn(dropbox, 'writeFile')
    jsonDrop.get().setVal(true)
    expect(dropbox.writeFile).toHaveBeenCalledWith('/jsondrop/val.json', 'true',
        dropbox.writeFile.mostRecentCall.args[2] # Don't care about callback
    )
  it  "with Array arg", ->
  	array = [1,2,3]
  	spyOn(dropbox, 'writeFile')
  	jsonDrop.get().setVal(array)
  	expect(dropbox.writeFile).toHaveBeenCalledWith('/jsondrop/array.json', '["_0","_1","_2"]',
        dropbox.writeFile.mostRecentCall.args[2] # Don't care about callback
    )
