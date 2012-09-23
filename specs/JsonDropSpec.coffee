if global? and require? and module?
  # Node.JS
  exports = global
  exports.JsonDrop =  require '../build/jsondrop'

describe "A suite", ->
  it "jsonDrop", ->
    expect(new JsonDrop().meth()).toBe(true)
