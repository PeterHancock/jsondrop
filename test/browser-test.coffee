# B R O W S E R   T E S T

# The constructor
describe "The API", ->
  # The Dropbox App key for jsondrop-test
  key = 'hEsTmWUoOSA=|PCASZmGZX0SfDWgEfpTs3vehLJpOin8NJfHio9NCeA=='
  jsondrop = new JsonDrop(key: key)
  it "should get set", ->
    ob = 
      x: 1
      y:
        x: 2
    node = jsondrop.get()
    node.setVal ob
    expect(node.getVal()).toBe ob


