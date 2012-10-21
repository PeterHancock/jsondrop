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
  it "should get set objects", ->
    ob = 
      x: 1
      y:
        z: 2
    runner = (cb) =>
      createJsondrop().get().setVal ob, (err) =>
        # Create a new JsonDrop to clear the cached values, forcing reads
        createJsondrop().get().getVal cb
    expectation = (val) -> expect(val).toEqual ob
    testAsync runner, 5000, expectation
  xit "should get set scalars", ->
    num= 10.5
    runner = (cb) =>
      createJsondrop().get().setVal num, (err) =>
        # Create a new JsonDrop to clear the cached values, forcing reads
        createJsondrop().get().getVal cb
    expectation = (val) -> expect(val).toBe num
    testAsync runner, 5000, expectation
  xit "should get set arrays", ->
    jsondrop = createJsondrop()
    array = [1,3,2]
    node = jsondrop.get()
    runner = (cb) ->
      node.setVal array, (err) ->
        # Create a new JsonDrop to clear the cached values, forcing reads
        jsondrop = createJsondrop()
        jsondrop.get().getVal cb
    expectation = (val) -> expect(val).toEqual array



