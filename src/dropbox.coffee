# The DropBox File System
class DropBoxFileSystem
	authorizeDropbox = (dropbox) ->
    dropbox.authDriver (new Dropbox.Drivers.Redirect(rememberUser: true))
    dropbox.authenticate (error, data) ->
      throw new Error(error) if error

	constructor: ({dropbox, key}) ->
    throw new Error 'Require a dropbox client instance or a dropbox key' unless dropbox or key
    if key
    	@dropbox = new Dropbox.Client(key: key, sandbox: true)
    else
      @dropbox = dropbox
    authorizeDropbox(@dropbox)

  remove: (path, callback) -> @dropbox.remove path, callback

  readdir: (path, callback) -> @dropbox.readdir path, callback

  readFile: (path, callback) -> @dropbox.readFile path, callback

  writeFile: (path, text, callback) -> @dropbox.writeFile path, text, callback
