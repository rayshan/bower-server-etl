gapi = require "googleapis"
rsvp = require "rsvp"

express = require 'express'
app = express()
dataApi = express.Router()

redis = require 'redis'
db = redis.createClient("/tmp/redis.sock")
db.on "error", (err) -> console.log err; return

###
# Config
###

config =
  ga:
    clientEmail: "1068634003933-b8cijec64sti0if00mnrbqfnrt7vaa7a@developer.gserviceaccount.com"
    # ask repo owner for GA Service Account key.pem, then export GA_KEY_PATH=path
    privateKeyPath: process.env.GA_KEY_PATH || null
    profile : "75972512"
    scopeUri : "https://www.googleapis.com/auth/analytics.readonly"
  types: ['traffic', 'ranking', 'geo']

###
# GA
###

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
    msg = "Error: process.env.GA_KEY_PATH is #{ process.env.GA_KEY_PATH }"
    console.log msg
    reject new Error msg
  else
    authClient.authorize (err, token) ->
      console.log "WIP: OAuthing w/ GA..."
      if err?
        console.log "Error: OAuth - ", err
        reject(err)
      else
        resolve(token)
        console.log "Success: server OAuthed w/ GA"
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
# Server & API
###

# invoked when /:type present in path
dataApi.param 'type', (req, res, next, id) ->
  if config.types.indexOf(id) is -1
    err = new Error "Wrong request data type."
    console.log "Error: #{ err.message }"
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
    authPromise.then(fetch).then transform
      .then (data) -> res.json data; return
      .catch (err) -> console.log "Error: ", err; return
    return

app.use dataApi
app.use express.static 'public'

server = app.listen 3000, ->
  console.log "Listening on port #{ server.address().port }"
  return