# vendor
Promise = require 'bluebird'
downloadCounts = Promise.promisify require 'npm-download-counts'
moment = require 'moment'

# custom
util = require "bUtil"
ga = require "googleAnalytics"
cache = require "cache"

# ==========

_gaQueryObj =
  'ids': 'ga:' + config.ga.profile
  # date range should be the same as npm query
  'start-date': '2014-03-15'
  'end-date': '2daysAgo'
  'metrics': 'ga:users'
  'dimensions': 'ga:userType,ga:date'
  'max-results': 10000

model = {}

model.name = 'users'

model.extract = ->
  util.etlLogger 'extract', @name

  # GA new / existing user data
  gaPromise = ga.gaRateLimiter.removeTokensAsync 1 # don't hammer GA server w/ too many concurrent reqs
    .then ga.fetch _gaQueryObj

  # npm download stats for bower
  # date range should be the same as gaQueryObj
  _npmStatStart = moment [2014, 2, 15] # 0-based month
  _npmStatEnd = moment().subtract('days', 2).toDate()
  npmPromise = downloadCounts 'bower', _npmStatStart, _npmStatEnd

  Promise.all [gaPromise, npmPromise]

model.transform = (data) ->
  util.etlLogger 'transform', @name

  gaData = data[0].rows
  gaData.forEach (d) ->
    d[0] = if d[0].indexOf('New') isnt -1 then 'N' else 'E'
    d[2] = +d[2]
    return

  npmData = data[1].map (day) -> [
    'npm'
    day.day.replace(/-/g, '')
    day.count
  ]

  gaData.concat npmData

model.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

module.exports = model
