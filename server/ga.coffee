# Vendor
p = require 'path'
Promise = require 'bluebird'
gapi = require "googleapis"
moment = require 'moment'
RateLimiter = require('limiter').RateLimiter
gaRateLimiter = Promise.promisifyAll new RateLimiter 1, 'second'
# don't hammer GA server w/ too many concurrent reqs

# Custom
config = require "./config"
gaQueries = require "./gaQueries"

# ==========

# define auth obj; used for init auth & fetches
authClient = new gapi.auth.JWT(
  config.ga.clientEmail,
  if process.env.NODE_ENV is 'development' then p.join __dirname, config.ga.privateKeyPath else null, # key as .pem file
  if process.env.NODE_ENV is 'production' then config.ga.privateKeyContent else null,
  [config.ga.scopeUri]
)

gaClient =
  obj: null
  expireAt: null # expires @ beginning of next day

# auth on bootstrap
authPromise = -> new Promise (resolve, reject) ->
  if gaClient.obj and moment().unix() < gaClient.expireAt
    resolve()
  else
    console.info "[INFO] OAuthing w/ GA..."
    authClient.authorize (err, token) ->
      # returns expires_in: 1403069828 and refresh_token: 'jwt-placeholder', not sure if 16 days or 44 yrs -_-
      if err
        reject new Error "[ERROR] OAuth error; err = #{ err }"
        console.log err
      else
        console.info "[SUCCESS] server OAuthed w/ GA."
        gapi.discover('analytics', 'v3').withAuthClient(authClient).execute (err, client) ->
          if err
            reject new Error "[ERROR] gapi.discover.execute, err = #{ err }"
          else
            gaClient.obj = client # reuse this client
            gaClient.expireAt = moment().add('days', 1).startOf('day').unix()
            resolve()
          return
      return
    return

fetch = (key) ->
  (xRateLimitRemaining) ->
    query = gaQueries[key]

    queryPromise = new Promise (resolve, reject) ->
      console.info "[INFO] fetching [#{ key }] from GA."
      gaClient.obj.analytics.data.ga.get(query.queryObj).execute (err, result) ->
        if err
          reject new Error "[ERROR] client.analytics.data.ga.get, err = #{ err.message }"
        else resolve result
        return
      return

    queryPromise.then query.transform
    # err catched in cache.coffee

# ==========

module.exports =
  validQueryTypes: Object.keys(gaQueries).concat 'overview'
  authPromise: authPromise
  gaRateLimiter: gaRateLimiter
  fetch: fetch