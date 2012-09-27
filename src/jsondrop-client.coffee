# The client API
class JsonDrop
	constructor: ({dropboxAdapter, key}) ->
    throw new Error '???' unless dropboxAdapter or key
    if key
      @dropbox = new DropBoxAdapter(key: key).getDropbox()
    else
      @dropbox = dropboxAdapter.getDropbox()

  # Get the dropbox instance
  getDropbox: -> @dropbox
