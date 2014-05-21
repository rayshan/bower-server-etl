# Vendor
redis = require 'redis'
rsvp = require 'rsvp'
request = require 'request'
moment = require 'moment'
later = require 'later'

# Custom
ga = require './ga'
config = require "./config"

# ==========
# cache data fetch responses via redis

fetch = (key) ->
  new rsvp.Promise (resolve, reject) ->
    _fetchFromCache = (key) ->
      console.info "[INFO] fetching [#{ key }] from cache."
      # fetch combined data source, 'all'
      if key is 'all'
        console.log ga.validQueryTypes
        db.mget ga.validQueryTypes, (err, res) ->
          if err
            error = new Error "[ERROR] redis - db.get(#{ key }) - #{ err }"
            console.error error
            reject error
          else
            result = {}
            ga.validQueryTypes.forEach (type, i) -> result[type] = JSON.parse res[i]; return
            resolve result
          return
        return
      else
        db.get key, (err, res) ->
          if err
            error = new Error "[ERROR] redis - db.get(#{ key }) - #{ err }"
            console.error error
            reject error
          else resolve JSON.parse res
          return
        return

    _fetchAndCache = {}
    _fetchAndCache.ga = ->
      ga.authPromise.then ga.fetch key
        .then (data) ->
          db.set key, JSON.stringify data
          # delete key at start of next day in case there's a midnight refresh
          db.expireat key, moment().add('days', 1).startOf('day').unix()
          console.info "[SUCCESS] fetched / cached [#{ key }] data."
          resolve data
          return
#        .catch (err) -> console.error "[ERROR] ", err; return
      return
    _fetchAndCache.overview = ->
      request {url: 'https://bower.herokuapp.com/packages', json: true}, (err, res, body) ->
        if err
          error = new Error "[ERROR] can't fetch package count from bower registry, err = #{ err }"
          console.error error
          reject error
        else
          data = totalPkgs: body.length
          db.set key, JSON.stringify data
          # delete key at start of next day in case there's a midnight refresh
          db.expireat key, moment().add('days', 1).startOf('day').unix()
          console.info "[SUCCESS] fetched / cached [#{ key }] data."
          resolve data
        return

    # fetch 'all' combined data sources
    if key is 'all'
      _fetchFromCache key
    else
      # fetch individual data source
      db.exists key, (err, res) ->
        if err              # redis err
          error = new Error "[ERROR] redis - error when checking db.exists(#{ key }), error = #{ err }"
          console.error error
          reject error
        else if res is 1    # already cached
          _fetchFromCache key
        else                # not cached
          console.info "[INFO] not cached / fetching [#{ key }] from GA."
          if key is 'overview'
            _fetchAndCache.overview()
          else
            _fetchAndCache.ga()
        return
    return

# ==========

allCached = false

init = ->
  # for dev
  db.flushdb() if process.env.NODE_ENV is 'development'

  fetchPromises = []
  ga.validQueryTypes.forEach (key) -> fetchPromises.push fetch key; return

  rsvp.all fetchPromises
    .then ->
      console.info "[SUCCESS] fetched & cached all data."
      allCached = true
      return
    .catch (err) ->
      console.error err
      return

  return

# ==========
# cron job to get data ready so 1st user of every day don't have to wait long

# set later to use local time (default = UTC)
later.date.localTime()
schedule = later.parse.recur().on(1).hour() # 1am; 24-hour format
# console.info later.schedule(schedule).next 5 # print next 5 occurrences of later schedule
timer = later.setInterval init, schedule # execute init on schedule

# ==========

db = redis.createClient config.db.socket # defaults to db 0
db.on "error", (err) -> console.error err; return

# ==========

module.exports =
  init: init
  fetch: fetch
  db: db
  allCached: -> allCached # get around module export caching