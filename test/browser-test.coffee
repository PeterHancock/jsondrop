# B R O W S E R   T E S T

testSetGetVal = (path, data) ->
  testAsync 10000, (complete) ->
    node = createJsondrop().get(path)
    node.setVal data, (err) ->
      node.getVal (err, val) ->
        expect(val).toEqual data
        createJsondrop().get(path).getVal (err, val) ->
          expect(val).toEqual data
          complete()

testAsync = (timeout, asyncTest) ->
  ready = false
  runs =>
    asyncTest () =>
      ready = true
  waitsFor((() -> ready), 'Operation took took too long', timeout)

createJsondrop = () ->
  # The Dropbox App key for jsondrop-test
  key = 'hEsTmWUoOSA=|PCASZmGZX0SfDWgEfpTs3vehLJpOin8NJfHio9NCeA=='
  new JsonDrop(key: key)

describe "The API", ->
  it "should get and set objects", ->
    ob =
      x: 1
      y:
        z: 2
    testSetGetVal 'test_object', ob
  it "should get and set scalars", ->
    testSetGetVal 'test_scalar', 10.5
  it "should get and set arrays", ->
    testSetGetVal 'test_array', [1, 2, 3]
