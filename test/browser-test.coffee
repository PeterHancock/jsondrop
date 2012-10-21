# B R O W S E R   T E S T

# The constructor

testAsync = (runner, timeout, expectation) ->
  ready = false
  rtn = null
  runs =>
    runner (err, val) =>
      rtn = val
      ready = true
  waitsFor((() -> ready), 'Operation took took too long', timeout)
  runs =>
    expectation rtn

createJsondrop = () ->
  # The Dropbox App key for jsondrop-test
  key = 'hEsTmWUoOSA=|PCASZmGZX0SfDWgEfpTs3vehLJpOin8NJfHio9NCeA=='
  new JsonDrop(key: key)

describe "The API", ->
  jsondrop = createJsondrop()
  it "should get set objects", ->
    ob = 
      x: 1
      y:
        z: 2
    node = jsondrop.get()
    #node.setVal ob
    # Create a new JsonDrop to clear the cached values, forcing reads
    jsondrop = createJsondrop()
    runner = (callback) -> jsondrop.get().getVal callback
    expectation = (val) -> expect(val).toEqual ob
    testAsync runner, 5000, expectation

  xit "should get set scalars", ->
    val = 10.5
    node = jsondrop.get()
    node.setVal val
    expect(jsondrop.get().getVal()).toBe val
  xit "should get set arrays", ->
    array= [1,3,2]
    node = jsondrop.get()
    node.setVal array
    expect(jsondrop.get().getVal()).toBe array


