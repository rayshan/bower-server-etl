# custom
util = require "bUtil"
ga = require "googleAnalytics"
cache = require "cache"

# ==========

_gaQueryObj =
  'ids': 'ga:' + config.ga.profile
  'start-date': '2014-03-15'
  'end-date': '2daysAgo'
  'metrics': 'ga:users'
  'dimensions': 'ga:userType,ga:date'
  'max-results': 10000

model = {}

model.name = 'users'

model.extract = ->
  util.etlLogger 'extract', @name
  ga.gaRateLimiter.removeTokensAsync 1 # don't hammer GA server w/ too many concurrent reqs
    .then ga.fetch _gaQueryObj

model.transform = (data) ->
  util.etlLogger 'transform', @name
  result = data.rows
  result.forEach (d) ->
    d[0] = if d[0].indexOf('New') isnt -1 then 'N' else 'E'
    d[2] = +d[2]
    return
  result

model.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

module.exports = model
