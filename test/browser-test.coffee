# B R O W S E R   T E S T

testSetGetVal = (path, data, expected) ->
  expected = if expected then expected else data
  testAsync 10000, (complete) ->
    node = createJsondrop().get(path)
    node.setVal data, (err) ->
      node.getVal (err, val) ->
        expect(val).toEqual expected
        createJsondrop().get(path).getVal (err, val) ->
          expect(val).toEqual expected
          complete()

testPushAndEach = () ->
  testAsync 10000, (complete) ->
    node = createJsondrop().get('array_node')
    docs = ['DOC 1', 'DOC 2', 'DOC 3']
    node.remove ->
      node.pushVal docs[0], ->
        node.pushVal docs[1], ->
          node.pushVal docs[2], ->
            node.each((val, node, index) ->
              expect(val).toEqual docs[index],
            complete)

testPushAndEachSerial = () ->
  testAsync 20000, (complete) ->
    node = createJsondrop().get('array_node')
    docs = ['DOC 1', 'DOC 2', 'DOC 3']
    order = 0
    node.remove ->
      node.pushVal docs[0], ->
        node.pushVal docs[1], ->
          node.pushVal docs[2], ->
            node.eachSeries((val, node, index) ->
              expect(index).toBe order
              order = order + 1
              expect(val).toEqual docs[index]
            complete)

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
  it "should push and iterate", testPushAndEach
  it "should push and iterate serially", testPushAndEachSerial
