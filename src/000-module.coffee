if global? and require? and module?
  exports = global
  exports.async = require('async')

reduceAsync = async.reduce

forEachAsync = async.forEach

mapAsync = async.map

class Mixin
  @mixin = (source) ->
    _.extend(@::, source)

Iterable =
  each: (iterator, callback) -> throw 'no each'

  forEach: (iterator, callback) ->
    @each iterator, callback

  map: (mapTo, callback) ->
    if not callback
      callback = mapTo
      mapTo = (element) -> element
    result = []
    collectElements = (element, node, index) ->
      result.push mapTo(element, node)
    @each collectElements, (err) ->
      return callback(err) if err
      callback(null, result)
