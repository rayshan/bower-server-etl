config = require "./config"
gapi = require "googleapis"
rsvp = require "rsvp"
express = require 'express'
redis = require 'redis'

###
# GA
###

# auth obj
authClient = new gapi.auth.JWT(
  config.ga.clientEmail,
  config.ga.privateKeyPath,
  null, # key as string, not needed due to key file
  [config.ga.scopeUri]
)

# auth on bootstrap
authPromise = new rsvp.Promise (resolve, reject) ->
  # returns expires_in: 1395623939 and refresh_token: 'jwt-placeholder', not sure if 16 days or 44 yrs -_-
  if !process.env.GA_KEY_PATH?
    msg = "ERROR: process.env.GA_KEY_PATH mismatch or #{ process.env.GA_KEY_PATH }"
    console.log msg
    reject new Error msg
  else
    authClient.authorize (err, token) ->
      console.log "WIP: OAuthing w/ GA..."
      if err?
        console.log "ERROR: OAuth, err = ", err
        reject(err)
      else
        resolve(token)
        console.log "SUCCESS: server OAuthed w/ GA."
  return

fetch = ->
  new rsvp.Promise (resolve, reject) ->
    gapi.discover('analytics', 'v3').execute (err, client) ->
      client.analytics.data.ga.get {
        'ids': "ga:" + config.ga.profile
        'start-date': '2014-03-15'
        'end-date': 'yesterday'
        'metrics': 'ga:visits'
        'dimensions': 'ga:visitorType,ga:date'
      }
      .withAuthClient authClient
      .execute (err, result) -> if err? then reject(err) else resolve result; return
      return
    return

transform = (data) ->
  new rsvp.Promise (resolve, reject) ->
    result = data.rows
    result.forEach (d) ->
      d[0] = if d[0] is 'New Visitor' then 'N' else 'E'
      return
    resolve result
    return

###
# cache GA response via redis
###
cache = {}

cache.fetch = (key) ->
  new rsvp.Promise (resolve, reject) ->
    db.exists key, (err, res) ->
      if err # redis err
        console.log "ERROR: redis - db.exists(#{ key }) - #{ err }"
        reject err
        return
      else if res is 1 # already cached
        console.log "INFO: cached / fetching from cache."
        db.get key, (err, res) ->
          if err
            console.log "ERROR: redis - db.get(#{ key }) - #{ err }"
            reject err
          else resolve JSON.parse res
          return
        return
      else
        console.log "INFO: not cached / fetching from GA."
        authPromise.then(fetch).then transform
          .then (data) ->
            db.set key, JSON.stringify(data)
            resolve data
            return
          .catch (err) -> console.log "ERROR: ", err; return

cache.init = ->
#  db.del "users" # for testing
  console.log "SUCCESS: Connected to Redis."
  cache.fetch "users" # no need to wait for this promise to resolve
  return

db = redis.createClient(config.db.socket)
db.on "connect", cache.init
db.on "error", (err) -> console.log err; return

###
# Server & API
###

app = express()
dataApi = express.Router()

# invoked when /:type present in path
dataApi.param 'type', (req, res, next, id) ->
  if config.types.indexOf(id) is -1
    err = new Error "Wrong request data type."
    console.log "ERROR: #{ err.message }"
    res.json 500, {error: err.message}
  else
    req.type = id
    next()
  return

dataApi.route '/data/:type'
  .all (req, res, next) -> # req logger
    console.log req.method, req.type, req.path
    next()
    return
  .get (req, res) ->
    cache.fetch("users").then (data) -> res.json data; return
    return

app.use dataApi
app.use express.static 'public'

server = app.listen 3000, ->
  console.log "Listening on port #{ server.address().port }"
  return