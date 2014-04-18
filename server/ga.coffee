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
  if !config.ga.privateKeyPath?
    msg = "ERROR: process.env.APP_GA_KEY_PATH mismatch or #{ config.ga.privateKeyPath }"
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
    order =
      Install: 1
      Uninstall: 2
      Register: 3
      Info: 4
      Search: 5
    icon =
      Install: 'download'
      Uninstall: 'trash-o'
      Register: 'pencil'
      Info: 'info'
      Search: 'search'

    new rsvp.Promise (resolve, reject) ->
      current = data[0].rows
      prior = data[1].rows

      _transform = (d) ->
        command = d[0].replace /\//g, '' # remove leading & trailing /
        command = command.charAt(0).toUpperCase() + command.slice 1 # Cap Case
        d[0] = command
        d[1] = +d[1]
        d[2] = +d[2]
        return
      current.forEach _transform
      prior.forEach _transform

      commandCheck = (d) -> d[0].indexOf("ed") is -1 and d[0] != "Searched"
      # keep only commands that isn't called on success; searched is deprecated
      result = current.filter (d) -> commandCheck(d)
        .map (d) ->
          command: d[0]
          order: order[d[0]]
          icon: icon[d[0]]
          metrics: [
            {
              type: 'users'
              order: 1
              current: d[1]
            }
            {
              type: 'uses'
              order: 2
              current: d[2]
            }
          ]

      getValue = (command, period, ed, valueType) ->
        ed = if ed then 'ed' else ''
        i = if valueType is 'users' then 1 else 2
        # catch edge case in case new command tracked and no prior history
        try
          period.filter((d) -> d[0] is command.command + ed)[0][i]
        catch error
          0

      getMetric = (command, type) ->
        command.metrics.filter (d) -> d.type is type

      result.forEach (command) ->
        # command with packages count ('-ed')
        if ["Install", "Uninstall", "Register", "Unregister"].indexOf(command.command) != -1
          command.metrics.push {
            type: 'packages'
            order: 3
            current: getValue command, current, true, 'packages'
          }

        command.metrics.forEach (metric) ->
          metric.prior = getValue command, prior, (if metric.type is 'packages' then true else false), metric.type
          metric.delta = metric.current / metric.prior - 1
          return

        return

      resolve result






# ==========

module.exports =
  validQueryTypes: Object.keys queries
  queries: queries
  authPromise: authPromise
  fetch: fetch