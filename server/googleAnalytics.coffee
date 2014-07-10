# Vendor
p = require 'path'

Promise = require 'bluebird'
gapi = require "googleapis"
moment = require 'moment'
RateLimiter = require('limiter').RateLimiter
gaRateLimiter = Promise.promisifyAll new RateLimiter 1, 3000
# don't hammer GA server w/ too many concurrent reqs

# Custom
config = require "config"

# ==========

# define auth obj; used for init auth & fetches
authClient = new gapi.auth.JWT(
  config.ga.clientEmail,
  if process.env.NODE_ENV is 'development' then p.join __dirname, config.ga.privateKeyPath else null, # key as .pem file
  if process.env.NODE_ENV is 'production' then config.ga.privateKeyContent else null,
  [config.ga.scopeUri]
)

serviceClient =
  obj: null
  expireAt: null # expires @ beginning of next day

# auth on bootstrap
authPromise = new Promise (resolve, reject) ->
  if serviceClient.obj and moment().unix() < serviceClient.expireAt
    resolve(); return
  else
    console.info "[INFO] OAuthing w/ GA..."
    authClient.authorize (err, token) ->
      # returns expires_in: 1403069828 and refresh_token: 'jwt-placeholder', not sure if 16 days or 44 yrs -_-
      if err
        reject new Error "[ERROR] OAuth error; err = #{ err }"
      else
        console.info "[SUCCESS] server OAuthed w/ GA."

        discover = gapi.discover('analytics', 'v3').withAuthClient(authClient).execute (err, client) ->
          if err
            reject new Error "[ERROR] gapi.discover.execute, err = #{ err }"
          else
            console.info "[SUCCESS] GA service discovered."
            serviceClient.obj = client # reuse this client
            serviceClient.expireAt = moment().add('days', 1).startOf('day').unix()
            resolve()
          return

        setTimeout discover, 1000
      return
  return

fetch = (queryObj) ->
  (xRateLimitRemaining) ->
    new Promise (resolve, reject) ->
      serviceClient.obj.analytics.data.ga.get(queryObj).execute (err, result) ->
        if err
          reject new Error "[ERROR] client.analytics.data.ga.get, err = #{ err.message }"
        else resolve result
        return
      return

# ==========

module.exports =
  authPromise: authPromise
  gaRateLimiter: gaRateLimiter
  fetch: fetch