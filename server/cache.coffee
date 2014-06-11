# Vendor
Promise = require 'bluebird'
redis = Promise.promisifyAll require 'redis'
request = Promise.promisifyAll require 'request'
moment = require 'moment'
later = require 'later'

# Custom
ga = require './ga'
config = require "./config"

# ==========

allCached = false
lastCachedTime =
  unix: null
  human: null
  RFC2616: null

# ==========
# cache data fetch responses via redis

fetch = (key) ->
  new Promise (resolve, reject) ->
    _fetchFromCache = (key) ->
      console.info "[INFO] fetching data [#{ key }] from cache."
      # fetch combined data source, 'all'
      if key is 'all'
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

    _cache = (data) ->
      db.set key, JSON.stringify data
      # delete key at start of next day in case there's a midnight refresh
      db.expireat key, moment().add('days', 1).startOf('day').unix()

      db.set "lastCachedTimeUnix", JSON.stringify moment().unix()
      db.expireat key, moment().add('days', 1).startOf('day').unix()

      console.info "[SUCCESS] fetched / cached [#{ key }] data."
      resolve data
      return

    _fetchAndCache = {}
    _fetchAndCache.ga = ->
      ga.authPromise
        .then ga.fetch key
        .then (data) -> _cache data; return
        .catch (err) -> console.error err; return
      return
    _fetchAndCache.overview = ->
      request.getAsync({url: 'https://bower.herokuapp.com/packages', json: true}).spread (res, body) ->
        _cache {totalPkgs: body.length}; return
      # error = new Error "[ERROR] can't fetch package count from bower registry, err = #{ err }"

    # ==========

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

init = ->
  # for dev
  # TODO: move to creating db client below
#  db.flushdb() if process.env.NODE_ENV is 'development'

  fetchPromises = []
  ga.validQueryTypes.forEach (key) -> fetchPromises.push fetch key; return

  getTime = (res) ->
    allCached = true
    if err then err = new Error "[ERROR] redis - db.get('lastCachedTimeUnix') - #{ err }"
    else
      lastCachedTime.unix = res # unix
      lastCachedTime.human = moment.unix(lastCachedTime.unix).format 'LLLL'
      lastCachedTime.RFC2616 = moment.unix(lastCachedTime.unix).utc().format 'ddd, DD MMM YYYY HH:mm:ss [GMT]'
      console.info "[SUCCESS] cached all data @ #{ lastCachedTime.human }"
    return

  # TODO: use bluebird's .map(, {concurrency: 1}) or gapi's batch execution to meet GA's 10 QPS limit
  Promise.all fetchPromises
    .then -> db.getAsync "lastCachedTimeUnix"
    .then getTime
    .catch (err) -> console.error err; return

  return

# ==========
# cron job to get data ready so 1st user of every day don't have to wait long

# set later to use local time (default = UTC)
later.date.localTime()
schedule = later.parse.recur().on('00:01:00').time() # 0:05; 24-hour format
#console.info later.schedule(schedule).next 5 # print next 5 occurrences of later schedule
timer = later.setInterval init, schedule # execute init on schedule

# ==========

# defaults to db 0
if process.env.NODE_ENV is 'development'
  db = redis.createClient config.db
else
  console.log config.db
  # using Redis Labs Redis Cloud, req auth
  db = redis.createClient config.db.port, config.db.hostname, no_ready_check: true
  db.auth config.db.auth.split(":")[1]

db.on "error", (err) -> console.error err; return

# ==========

module.exports =
  init: init
  fetch: fetch
  db: db
  allCached: -> allCached # func to get around module export caching
  lastCachedTime: -> lastCachedTime