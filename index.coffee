gapi = require "googleapis"
rsvp = require "rsvp"
express = require 'express'
app = express()
dataApi = express.Router()

###
# Config
###

config =
  ga:
    clientEmail: "1068634003933-b8cijec64sti0if00mnrbqfnrt7vaa7a@developer.gserviceaccount.com"
    # ask repo owner for GA Service Account key.pem, then export GA_KEY_PATH=path
    privateKeyPath : process.env.GA_KEY_PATH
    profile : "75972512"
    scopeUri : "https://www.googleapis.com/auth/analytics.readonly"
    impersonatedUser : "stats.bower.io"
  types: ['traffic', 'ranking', 'geo']

###
# GA
###

authClient = new gapi.auth.JWT(
  config.ga.clientEmail,
  config.ga.privateKeyPath,
  null, # key as string, not needed due to key file
  [config.ga.scopeUri],
  config.ga.impersonatedUser
)

# auth on bootstrap
authPromise = new rsvp.Promise (resolve, reject) ->
  authClient.authorize (err, token) -> if err? then reject(err) else resolve(token); return
  # returns expires_in: 1395623939 and refresh_token: 'jwt-placeholder', not sure if 16 days or 44 yrs -_-
  console.log "Server authed w/ GA."
  return

fetch = ->
  new rsvp.Promise (resolve, reject) ->
    gapi.discover('analytics', 'v3').execute (err, client) ->
      client.analytics.data.ga.get {
        'ids': "ga:" + config.ga.profile
        'start-date': '2014-03-01'
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
    throw "Wrong request data type."
  else
    req.type = id
    next(); return

dataApi.route '/data/:type'
  .all (req, res, next) -> # req logger
    console.log req.method, req.type, req.path
    next()
    return
  .get (req, res, next) ->
    authPromise.then(fetch).then transform
      .then (data) -> res.json(data); return
      .catch (err) -> console.log "error: ", err; return
    return

app.use dataApi
app.use express.static('public')

server = app.listen 3000, ->
  console.log "Listening on port #{ server.address().port }"
  return