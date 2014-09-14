# Vendor
p = require 'path'

Promise = require 'bluebird'

GAPI = require "googleapis"
ga = Promise.promisifyAll GAPI.analytics('v3').data.ga

RateLimiter = require('limiter').RateLimiter
gaRateLimiter = Promise.promisifyAll new RateLimiter 1, 2000
# don't hammer GA server w/ too many concurrent reqs

# ==========

# define auth obj; used for init auth & fetches
authClient = new GAPI.auth.JWT(
  config.ga.clientEmail,
  if process.env.NODE_ENV is 'development' then p.join __dirname, config.ga.privateKeyPath else null, # key as .pem file
  if process.env.NODE_ENV is 'production' then config.ga.privateKeyContent else null,
  [config.ga.scopeUri]
)

#serviceClient =
#  obj: null
#  expireAt: null # expires @ beginning of next day

# auth on bootstrap
authPromise = new Promise (resolve, reject) ->
  console.info "[INFO] OAuthing w/ GA..."
  authClient.authorize (err, token) ->
    # returns expires_in: 1406182540 and refresh_token: 'jwt-placeholder', not sure if 16 days or 44 yrs -_-
    if err
      reject new Error "[ERROR] OAuth error; err = #{ err }"
    else
      console.info "[SUCCESS] server OAuthed w/ GA."
      resolve(token)
    return
  return

fetch = (queryObj) ->
  queryObj.auth = authClient # inserting authClient into queryObj b/c GA.data.ga.get takes 1 object as param

  # don't hammer GA server w/ too many concurrent reqs
  gaRateLimiter.removeTokensAsync(1)
    .then -> ga.getAsync queryObj
    .catch (err) -> throw new Error "[ERROR] GA.data.ga.get, err = #{ err.message }"
    .get 0 # for some reason data[1] is whole object returned by request again


# ==========

module.exports =
  authPromise: authPromise
  gaRateLimiter: gaRateLimiter
  fetch: fetch
