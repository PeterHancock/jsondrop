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
  it "should get and set objects", ->
    path = 'test_object'
    ob = 
      x: 1
      y:
        z: 2
    runner = (cb) =>
      node = createJsondrop().get(path)
      node.setVal ob, (err) =>
        # Create a new JsonDrop to clear the cached values, forcing reads
        createJsondrop().get(path).getVal cb
      node.getVal (er, val) ->
        expect(val).toEqual ob
    expectation = (val) -> expect(val).toEqual ob
    testAsync runner, 5000, expectation
  it "should get and set scalars", ->
    path = 'test_scalar'
    num= 10.5
    runner = (cb) =>
      node = createJsondrop().get(path)
      node.setVal num, (err) =>
        # Create a new JsonDrop to clear the cached values, forcing reads
        createJsondrop().get(path).getVal cb
      node.getVal (er, val) ->
        expect(val).toEqual num
    expectation = (val) -> expect(val).toBe num
    testAsync runner, 5000, expectation
  it "should get and set arrays", ->
    path = 'test_array'
    array = [1,3,2]
    runner = (cb) ->
      node = createJsondrop().get(path)
      node.setVal array, (err) ->
        # Create a new JsonDrop to clear the cached values, forcing reads
        jsondrop = createJsondrop()
        jsondrop.get(path).getVal cb
      node.getVal (er, val) ->
        expect(val).toEqual array
    expectation = (val) -> expect(val).toEqual array
    testAsync runner, 10000, expectation



