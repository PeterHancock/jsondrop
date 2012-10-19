# B R O W S E R   T E S T

# The constructor
describe "The API", ->
  # The Dropbox App key for jsondrop-test
  key = 'hEsTmWUoOSA=|PCASZmGZX0SfDWgEfpTs3vehLJpOin8NJfHio9NCeA=='
  jsondrop = new JsonDrop(key: key)
  it "should get set objects", ->
    ob = 
      x: 1
      y:
        z: 2
    node = jsondrop.get()
    node.setVal ob
    expect(jsondrop.get().getVal()).toBe ob
    #expect(jsondrop.get().child('y').getVal()).toBe ob.y
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


