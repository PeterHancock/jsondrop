# The DropBox File System
class DropBoxFileSystem

	constructor: (dropbox) ->
        @dropbox = dropbox

  remove: (path, callback) -> @dropbox.remove path, callback

  readdir: (path, callback) -> @dropbox.readdir path, callback

  readFile: (path, callback) -> @dropbox.readFile path, callback

  writeFile: (path, text, callback) -> @dropbox.writeFile path, text, callback
