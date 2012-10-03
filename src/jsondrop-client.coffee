# The client API
class JsonDrop
	constructor: ({dropboxAdapter, key}) ->
    throw new Error 'Require a dropboxAdapter or a dropbox key' unless dropboxAdapter or key
    if key
      @dropbox = new DropBoxAdapter(key: key).getDropbox()
    else
      @dropbox = dropboxAdapter.getDropbox()

  # Get the dropbox instance
  getDropbox: -> @dropbox

  get: (path) ->
    if path
      return new Node(path: JsonDrop.normalizePath path)
    else
      return new Node(path: '/')

  @normalizePath = (path) ->
    '/' + path.replace(/^\/*/,'').replace(/\/*$/, '')

class Node
  constructor: ({@path, defaultVal}) ->
	   @val = null