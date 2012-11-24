if global? and require? and module?
  exports = global
  exports.async = require('async')

reduceAsync = async.reduce

forEachAsync = async.forEach

mapAsync = async.map

# Mixins a la http://arcturo.github.com/library/coffeescript/03_classes.html
extend = (obj, mixin) ->
  obj[name] = method for name, method of mixin
  obj

include = (klass, mixin) ->
  extend klass::, mixin
