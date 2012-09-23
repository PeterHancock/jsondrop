# Main class
class JsonDrop
  # A meth
  meth: -> true

if module?.exports?
  # We're a node.js module, so export the Dropbox class.
  module.exports = JsonDrop
else if window?
  # We're in a browser, so add Dropbox to the global namespace.
  window.JOSNDrop = JSONDrop
else
  throw new Error('This library only supports node.js and modern browsers.')
