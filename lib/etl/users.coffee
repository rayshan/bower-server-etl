# vendor
Promise = require 'bluebird'
downloadCountsAsync = Promise.promisify require 'npm-download-counts'
moment = require 'moment'

# custom
util = require "bUtil"
gaExtractor = require "googleAnalytics"
cache = require "cache"

# ==========

etl = {}
etl.name = 'users'
etl.gaQueryObj =
  # date range should be the same as npm query
  'start-date': '2014-03-15' # 2014-03-11 - 1st day w/ significant data
  'end-date': '2daysAgo'
  'metrics': 'ga:users'
  'dimensions': 'ga:userType,ga:date'

etl.extract = ->
  util.etlLogger 'extract', @name

  # extract GA new / existing user data
  gaPromise = gaExtractor.extract @gaQueryObj

  # extract npm download stats for bower
  # date range should be the same as gaQueryObj
  _npmStatStart = moment [2014, 2, 15] # 0-based month
  _npmStatEnd = moment().subtract(2, 'days').toDate()
  npmPromise = downloadCountsAsync 'bower', _npmStatStart, _npmStatEnd

  Promise.all [gaPromise, npmPromise]

etl.transform = (data) ->
  util.etlLogger 'transform', @name

  uniformLength = data[0].length / 2
  gaData = data[0]
  gaData.forEach (d) ->
    d[0] = if d[0].indexOf('New') isnt -1 then 'N' else 'E'
    d[2] = +d[2]
    return

  # GA 2daysAgo may not always return the same final day depending on when query rans
  npmData = data[1][0..(uniformLength - 1)]
  npmData = npmData.map (day) -> [
    'npm'
    day.day.replace(/-/g, '')
    day.count
  ]

  gaData.concat npmData

etl.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

module.exports = etl
