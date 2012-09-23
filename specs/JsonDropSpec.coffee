# Import jsondrop for testing with Node.js
if global? and require? and module?
  exports = global
  exports.JsonDrop =  require '../build/jsondrop'

# Tests for the client API
describe "The Client API", ->
  it "should have tests...", ->
    expect(new JsonDrop().meth()).toBe true
