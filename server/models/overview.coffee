# vendor
Promise = require 'bluebird'
request = Promise.promisifyAll require 'request'
# using this instead of http.get to not deal w/ streams

# custom
util = require "bUtil"
cache = require "cache"

# ==========

model = {}
modelName = 'overview'

model.extract = ->
  util.etlLogger 'extract', modelName

  console.info "[INFO] fetching [#{ modelName }] from GA."
  request.getAsync {url: 'https://bower.herokuapp.com/packages', json: true}
    .spread (res, body) -> totalPackages: body.length
    .catch (err) ->
      throw new Error "Can't fetch package count from bower registry, err = #{ err }."

model.transform = (data) -> data # not needed

model.load = (data) ->
  util.etlLogger 'load', modelName
  cache.cache modelName, data

module.exports = model