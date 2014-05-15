# Vendor
redis = require 'redis'
rsvp = require 'rsvp'
request = require 'request'
moment = require 'moment'

# Custom
ga = require './ga'
config = require "./config"

# ==========

allCached = false

# cache GA response via redis

fetch = (key) ->
  new rsvp.Promise (resolve, reject) ->
    _fetchFromCache = ->
      console.info "[INFO] fetching [#{ key }] from cache."
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
      ga.authPromise.then ga.fetch key # .then transform
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

    # fetch combined data source, 'all'
    if key is 'all'
      resolve ''
      return
    else
      # fetch individual data source
      db.exists key, (err, res) ->
        if err              # redis err
          error = new Error "[ERROR] redis - error when checking db.exists(#{ key }), error = #{ err }"
          console.error error
          reject error
          return
        else if res is 1    # already cached
          _fetchFromCache()
        else                # not cached
          console.info "[INFO] not cached / fetching [#{ key }] from GA."
          if key is 'overview'
            _fetchAndCache.overview()
          else
            _fetchAndCache.ga()
    return

init = ->
  console.info "[SUCCESS] Connected to Redis."

  # for dev
  db.flushdb() if process.env.NODE_ENV is 'dev'

  fetchPromises = []
  ga.validQueryTypes.forEach (key) -> fetchPromises.push fetch key; return

  rsvp.all fetchPromises
    .then ->
      console.info "[SUCCESS] all fetched & cached."
      allCached = true
      return
    .catch (err) ->
      console.error err
      return

  return

db = redis.createClient config.db.socket # defaults to db 0
db.on "error", (err) -> console.error err; return

module.exports =
  init: init
  fetch: fetch
  db: db
  allCached: -> allCached # get around module export caching