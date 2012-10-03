# The DropBox adapter
class DropBoxAdapter
	authorizeDropbox = (dropbox) ->
    dropbox.authDriver (new Dropbox.Drivers.Redirect(rememberUser: true))	
		
	constructor: ({dropbox, key}) ->
    throw new Error 'Require a dropbox client instance or a dropbox key' unless dropbox or key
    if key
    	@dropbox = new Dropbox.Client(key: key, sandbox: true)
    else 
      @dropbox = dropbox
    authorizeDropbox(@dropbox)
    
  # Get the dropbox instance
  getDropbox: -> @dropbox

  
