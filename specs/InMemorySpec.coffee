# Import jsondrop for testing with Node.js
if global? and require? and module?
  exports = global
  exports.JsonDrop =  require '../build/jsondrop'
  exports._ = require("underscore")

# Testing the in memory file system
describe "The in memory filesystem", ->
  fs = new JsonDrop.InMemory()
  it "should handle non-existent dirs correctly", ->
    dirs = null
    fs.readdir '/some/path', (err, entries) ->
      dirs = entries
    expect(dirs).toEqual []
  it "should handle non-existent files correctly", ->
    text = 'notnull'
    fs.readFile '/some/path/file', (err, txt) ->
      text = txt
    expect(text).toEqual null
  it "should write files correctly", ->
    fs.writeFile '/some/path/file', '123', (err) ->
    text = null
    fs.readFile '/some/path/file', (err, txt) -> text = txt
    expect(text).toBe '123'
    

# Testing JsonDrop with an in memory file system
describe "Basic CRUD", ->
  jsonDrop = JsonDrop.inMemory()
  rootNode = jsonDrop.get()
  it "Non existent nodes should have an empty object value", ->
    rootNode.getVal (err, val) ->
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
      rootNode.child('y').getVal (err, val) ->
      rootNode.getVal (err, val) ->
        expect(val).toEqual {x:1, y: 2}
  
  


