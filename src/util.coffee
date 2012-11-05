if global? and require? and module?
  exports = global
  exports.async = require('async')

reduceAsync = async.reduce

forEachAsync = async.forEach

mapAsync = async.map
