# B R O W S E R   T E S T

testSetGetVal = (path, data, expected) ->
  expected = if expected then expected else data
  testAsync 10000, (complete) ->
    withJsondrop (jsonDrop) ->
        node = jsonDrop.get(path)
        node.set data, (err) ->
          node.get (err, val) ->
            expect(val).toEqual expected
            jsonDrop.get(path).get (err, val) ->
              expect(val).toEqual expected
              complete()

testPushAndEach = () ->
  testAsync 10000, (complete) ->
      withJsondrop (jsonDrop) ->
        node = jsonDrop.get('array_node')
        docs = ['DOC 1', 'DOC 2', 'DOC 3']
        node.remove ->
          node.pushAll docs..., () ->
            node.each((val, node, index) ->
                expect(val).toEqual docs[index],
              complete)

testPushAndEachSerial = () ->
  testAsync 20000, (complete) ->
      withJsondrop (jsonDrop) ->
        node = jsonDrop.get('array_node')
        docs = ['DOC 1', 'DOC 2', 'DOC 3']
        order = 0
        node.remove ->
          node.pushAll docs..., ->
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

withJsondrop = (callback) ->
  console.log('here')
  dropbox = new Dropbox.Client(key: 'xddkqsy965r8sir', sandbox: true)
  jsonDrop = JsonDrop.forDropbox(dropbox)
  #dropbox.authDriver (new Dropbox.Drivers.Redirect(rememberUser: true))
  dropbox.authenticate (err, data) ->
      throw new Error(err) if err
      return callback(jsonDrop)

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
