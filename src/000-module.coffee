if global? and require? and module?
  exports = global
  exports._ = require('underscore')

class Mixin
  @mixin = (source) ->
    _.extend(@::, source)

Iterable =
  each: (iterator, callback) -> throw 'No each'

  eachSeries: (iterator, callback) -> throw 'No eachSeries'

  map: (mapTo, callback) ->
    @_mapCommon mapTo, callback, _.bind(@each, @)

  mapSeries: (mapTo, callback) ->
    @_mapCommon mapTo, callback, _.bind(@eachSeries, @)

  _mapCommon: (mapTo, callback, eachMethod) ->
    if not callback
      callback = mapTo
      mapTo = (element) -> element
    result = []
    collectElements = (element, node, index) ->
      result.push mapTo(element, node)
    eachMethod collectElements, (err) ->
      return callback(err) if err
      callback(null, result)
