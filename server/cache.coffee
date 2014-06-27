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

_fetchFromCache = (key) ->
  console.info "[INFO] fetching data [#{ key }] from cache."
  if key is 'all' # fetch combined data source, 'all'
    db.mgetAsync(ga.validQueryTypes).then (res) ->
      result = {}
      ga.validQueryTypes.forEach (type, i) -> result[type] = JSON.parse res[i]; return
      result
  else # fetch individual data source
    db.getAsync(key).then (res) -> JSON.parse res

_cache = (key) -> (data) ->
  setData = db.setAsync key, JSON.stringify data
  # delete key at start of next day
  expireAt = db.expireatAsync key, moment().add('days', 1).startOf('day').unix()
  setTime = db.setAsync "lastCachedTimeUnix", JSON.stringify moment().unix()

  Promise.all([setData, expireAt, setTime]).then ->
    console.info "[SUCCESS] fetched / cached [#{ key }] data."; return

fetch = (key) ->
  if key is 'all' # fetch 'all' combined data sources
    _fetchFromCache key
  else # fetch individual data source
    db.existsAsync(key).then (res) ->
      if res is 1 # already cached
        _fetchFromCache key
      else # not cached
        console.info "[INFO] [#{ key }] not cached."
        if key is 'overview'
          request.getAsync {url: 'https://bower.herokuapp.com/packages', json: true}
            .spread (res, body) -> totalPkgs: body.length
            .then _cache key
            .catch (err) ->
              console.error new Error "[ERROR] can't fetch package count from bower registry, err = #{ err }"
              return
        else
          ga.gaRateLimiter.removeTokensAsync 1 # don't hammer GA server w/ too many concurrent reqs
            .then ga.fetch key
            .then _cache key

# ==========

init = ->
  # always flush db even on prod due to infrequent deploys & data schema still in flux
  db.flushdb() # if process.env.NODE_ENV is 'development'

  # need delay to ensure google server knows about auth before executing queries
  ga.authPromise().delay(3000).then ->
    fetchPromises = []
    ga.validQueryTypes.forEach (key) -> fetchPromises.push fetch key; return

    setLastCachedTime = (res) ->
      # if err then err = new Error "[ERROR] redis - db.get('lastCachedTimeUnix') - #{ err }"
      lastCachedTime.unix = res # unix
      lastCachedTime.human = moment.unix(lastCachedTime.unix).format 'LLLL'
      lastCachedTime.RFC2616 = moment.unix(lastCachedTime.unix).utc().format 'ddd, DD MMM YYYY HH:mm:ss [GMT]'
      allCached = true
      console.info "[SUCCESS] cached all data @ #{ lastCachedTime.human }"
      return

    # TODO: use bluebird's .map(, {concurrency: 1}) or gapi's batch execution to meet GA's 10 QPS limit
    Promise.all fetchPromises
      .then -> db.getAsync "lastCachedTimeUnix"
      .then setLastCachedTime
      .catch (err) -> console.error err; return

    return

  return

# ==========
# cron job to get data ready so 1st user of every day don't have to wait long

# set later to use local time (default = UTC, later doesn't support specific tz)
later.date.localTime()
# catch/fetch a little later than midnight in case there's a midnight refresh
schedule = later.parse.recur().on('00:01:00').time() # 0:05; 24-hour format
#console.info later.schedule(schedule).next 5 # print next 5 occurrences of later schedule
timer = later.setInterval init, schedule # execute init on schedule

# ==========

# defaults to db 0
if process.env.NODE_ENV is 'development'
  db = redis.createClient config.db
else
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