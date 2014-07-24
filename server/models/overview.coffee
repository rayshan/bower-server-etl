# vendor
Promise = require 'bluebird'
request = Promise.promisifyAll require 'request'
# using this instead of http.get to not deal w/ streams

# custom
util = require "bUtil"
cache = require "cache"

# ==========

model = {}
model.name = 'overview'

model.extract = ->
  util.etlLogger 'extract', @name

  console.info "[INFO] fetching [#{@name}] from GA."
  request.getAsync {url: 'https://bower.herokuapp.com/packages', json: true}
    .spread (res, body) -> totalPackages: body.length
    .catch (err) ->
      throw new Error "Can't fetch package count from bower registry, err = #{ err }."

model.transform = (data) -> data # not needed

model.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

module.exports = model
