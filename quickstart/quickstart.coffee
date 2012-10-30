#To get started with jsondrop simply put jsondrop and her dependencies in the *&lt;head&gt;* tag of your webapp.
#    &lt;script type="test/javascript" src="?/jsondrop.js"&gt;&lt;script&gt;
#Jsondrop is now available!

#To create your datastore in your dropbox
#To demonstrate the API we will use an in memory backend
jsonDrop = JsonDrop.inMemory()

#Data is written to a Node that represents an end point.

db = jsonDrop.get('db')

version = db.child('version')

#JsonDrop supports three data structures

#Scalars that map to th Javascript String, Numeric...
version.setVal 0.1, (err) ->

#
version.getVal (err, val) ->
  console.assert 0.1 is val

db.getVal (err, val) ->
  console.assert 0.1 is val.version
