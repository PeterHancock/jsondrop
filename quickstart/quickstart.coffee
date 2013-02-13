#To get started with jsondrop simply put jsondrop and her dependencies in the *&lt;head&gt;* tag of your webapp.
#    &lt;script type="test/javascript" src="?/jsondrop.js"&gt;&lt;script&gt;
#Jsondrop is now available!

#To create your datastore in your dropbox
#To demonstrate the API we will use an in memory backend
jsonDrop = JsonDrop.inMemory()

#Data is written to a *node* representing an address to store data.  A node has a *path* property representing the location
db = jsonDrop.get('db')
console.assert 'db' == db.path

#These statements are equivalent
version = jsonDrop.get('db/version')
version = db.child('version')

#Writing data to and reading data from a node
#--

#Use the *setVal* function of Node to persist a value against the node.  *setVal* also requires a callback function for handling write failures
version.setVal 0.1, (err) ->

#The value of a node can be retrieved with the *getVal* function of Node.  A callback is passed to the function that recieves the value or an error if the read failures  
version.getVal (err, val) ->
  console.assert 0.1 is val
#Note that the value of the parent node is not changed
db.getVal (err, val) ->
  console.assert ! val

#Nodes can be deleted with *remove*
version.remove (err) ->
  version.getVal (err, val) ->
    console.assert ! val

#As well as scalar values (String, Numeric, etc), JsonDrop also works with Object and Arrat values:

#Objects values
#--
schema = db.child 'schema'
schema.setVal {contacts: ':Array'}, (err) ->

schema.getVal (err, val) ->
  console.log 'scheme: ', val  


#Array values
#-- 
contacts = []
contacts.push {name: 'James', email: 'bondjamesbond@mi6.co.uk'}
contacts.push {name: 'Ernst', email: 'blofeld@spectre.org'}

contactsNode = db.child 'contacts'

contactsNode.setVal contacts, (err) ->

contactsNode.getVal (err, val) ->
  console.assert val[0].name == 'James'
  console.log 'Arrays are retrieved as is', val

#Nodes as Arrays
#--

#Storing many large documents in one node value may have a performance cost and *Node Arrays* can be a good alternative:

#Nodes can behave as an array of child nodes by using the *pushVal* method is used to add children.
#The child name created ensures the natural order of elements.
contactsNode.pushVal {name: 'Auric', email: 'goldfinger@smersh.org'},
  #The child argument is the node representing the appended value
  (err, child) -> console.log child.path

#Lets add another val
contactsNode.pushVal {name: 'James', email: 'bondjamesbond@mi6.co.uk'}, (err, child) ->

#There are iteration methods for working with Array Nodes
#each asynchronously iterates through eac item
contactsNode.each(
  (item, child, index) -> console.log child, " = contactsNode[#{index}] = ", item
  (err) -> alert err if err)

#map creates an array consisting of the mapping function applied to each item
contactsNode.map(
  (element) -> element.name
  (err, result) ->
    alert err if err
    console.log 'contactsNode.map = ', result)

# map with no mapping function uses the identity map
contactsNode.map (err, result) ->
  alert err if err
  console.log 'contactsNode.map = ', result