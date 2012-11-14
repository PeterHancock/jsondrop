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
#Note that the value of the parent node is correctly updated too
db.getVal (err, val) ->
  console.assert 0.1 is val.version
  

#JsonDrop supports three types of data structures
#Scalar values (String, Numeric, etc)
#--

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

# Arrays are represented as objects with naturally ordered keys
contactsNode.getVal (err, val) ->
  console.assert val._0.name == 'James'
  console.log 'Arrays a retrieved as Objects with ordered keys', val


# To add elements to the 'array' use pushVal
contactsNode.pushVal {name: 'Auric', email: 'goldfinger@smersh.org'}, (err, child) ->
  # The child argument is the node representing the appended element
  console.log child.path
  child.getVal (err, val) ->
    console.log val
    console.assert val.name == 'Auric'

