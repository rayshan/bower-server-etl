# Vendor
gapi = require "googleapis"
rsvp = require "rsvp"

# Custom
config = require "./config"

# ==========

###
# generic GA util
###

# define auth obj; used for init auth & fetches
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
      if err? then console.log "ERROR: OAuth, err = ", err; reject err
      else
        resolve(token)
        console.log "SUCCESS: server OAuthed w/ GA."
      return
  return

fetch = (key) ->
  ->
    query = queries[key]
    promises = []

    query.queryObjs.forEach (queryObj) ->
      promise = new rsvp.Promise (resolve, reject) ->
        gapi.discover('analytics', 'v3').execute (err, client) ->
          if err? then reject err
          else
            client.analytics.data.ga.get queryObj
              .withAuthClient authClient
              .execute (err, result) -> if err? then reject err else resolve result; return
          return
        return
      promises.push promise
      return

    rsvp.all(promises).then query.transform

###
# define queries
###

queries = {}
queries.users =
  queryObjs: [
    {
      'ids': 'ga:' + config.ga.profile
      'start-date': '2014-03-15'
      'end-date': 'yesterday'
      'metrics': 'ga:visits'
      'dimensions': 'ga:visitorType,ga:date'
    }
  ]
  transform: (data) ->
    new rsvp.Promise (resolve, reject) ->
      result = data[0].rows
      result.forEach (d) ->
        d[0] = if d[0] is 'New Visitor' then 'N' else 'E'
        d[2] = +d[2]
        return
      resolve result
      return

queries.commands =
  queryObjs: [
    { # current week
      'ids': 'ga:' + config.ga.profile
      'start-date': '7daysAgo'
      'end-date': 'yesterday'
      'metrics': 'ga:visitors,ga:pageviews'
      'dimensions': 'ga:pagePathLevel1'
    }
    { # prior week
      'ids': 'ga:' + config.ga.profile
      'start-date': '14daysAgo'
      'end-date': '8daysAgo'
      'metrics': 'ga:visitors,ga:pageviews'
      'dimensions': 'ga:pagePathLevel1'
    }
  ]
  transform: (data) ->
    new rsvp.Promise (resolve, reject) ->
      current = data[0].rows
      prior = data[1].rows

      current.forEach (d) ->
        d[0] = d[0].replace /\//g, ''
        d[1] = +d[1]
        d[2] = +d[2]
        return
      prior.forEach (d) ->
        d[0] = d[0].replace /\//g, ''
        d[1] = +d[1]
        d[2] = +d[2]
        return

      result = current.filter (d) -> d[0].indexOf("ed") is -1
        .map (d) ->
          command: d[0]
          current: {uses: +d[1], packages: +d[2]}

      result.forEach (command) ->
        command.prior =
          uses: prior.filter((d) -> d[0] is command.command)[0][1]
          packages: prior.filter((d) -> d[0] is command.command)[0][2]
        command.delta =
          uses: command.current.uses / command.prior.uses - 1
          packages: command.current.packages / command.prior.packages - 1

        switch command.command
          when "install", "uninstall", "register", "unregister"
            command.current.successes = current.filter((d) -> d[0] is command.command + 'ed')[0][2]
            command.prior.successes = prior.filter((d) -> d[0] is command.command + 'ed')[0][2]
            command.delta.successes = command.current.successes / command.prior.successes - 1
        return

      resolve result






# ==========

module.exports =
  validQueryTypes: Object.keys queries
  queries: queries
  authPromise: authPromise
  fetch: fetch