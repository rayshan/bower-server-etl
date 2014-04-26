# Vendor
gapi = require "googleapis"
rsvp = require "rsvp"
_find = require 'lodash-node/modern/collections/find' # to be replaced w/ array.prototype.find w/ node --harmony
gh = require './github'

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
  # console.log "console.log config.ga.privateKeyPath = " + config.ga.privateKeyPath
  # returns expires_in: 1395623939 and refresh_token: 'jwt-placeholder', not sure if 16 days or 44 yrs -_-
  if !config.ga.privateKeyPath?
    msg = "ERROR: process.env.APP_GA_KEY_PATH mismatch or #{ config.ga.privateKeyPath }"
    console.error msg
    reject new Error msg
  else
    authClient.authorize (err, token) ->
      console.log "WIP: OAuthing w/ GA..."
      if err then console.error "ERROR: OAuth, err = ", err; reject err
      else
        resolve(token)
        console.info "SUCCESS: server OAuthed w/ GA."
      return
  return

fetch = (key) ->
  ->
    query = queries[key]
    promises = []

    query.queryObjs.forEach (queryObj) ->
      promise = new rsvp.Promise (resolve, reject) ->
        gapi.discover('analytics', 'v3').execute (err, client) ->
          if err then reject err
          else
            client.analytics.data.ga.get queryObj
              .withAuthClient authClient
              .execute (err, result) -> if err then reject err else resolve result; return
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
      'metrics': 'ga:users'
      'dimensions': 'ga:userType,ga:date'
    }
  ]
  transform: (data) ->
    new rsvp.Promise (resolve, reject) ->
      result = data[0].rows
      result.forEach (d) ->
        d[0] = if d[0].indexOf('New') != -1 then 'N' else 'E'
        d[2] = +d[2]
        return
      resolve result
      return

util =
  removeSlash: (input) -> input.replace /\//g, '' # remove leading & trailing /

queries.commands =
  queryObjs: [
    { # current week
      'ids': 'ga:' + config.ga.profile
      'start-date': '7daysAgo'
      'end-date': 'yesterday'
      'metrics': 'ga:users,ga:pageviews'
      'dimensions': 'ga:pagePathLevel1'
    }
    { # prior week
      'ids': 'ga:' + config.ga.profile
      'start-date': '14daysAgo'
      'end-date': '8daysAgo'
      'metrics': 'ga:users,ga:pageviews'
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
        command = util.removeSlash(d[0])
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
            {metric: 'users', order: 1, current: d[1]} # ga:users
            {metric: 'uses', order: 2, current: d[2]} # ga:pageviews
          ]

      getValue = (command, period, ed, valueType) ->
        ed = if ed then 'ed' else ''
        i = if valueType is 'users' then 1 else 2 # else pkgs
        # catch edge case in case new command tracked and no prior history
        try
          _find(period, (d) -> d[0] is command.command + ed)[i]
        catch error
          0 # if not found, command tracking wasn't implemented

      result.forEach (command) ->
        # command with pkgs count ('-ed')
        if ["Install", "Uninstall", "Register", "Unregister"].indexOf(command.command) != -1
          command.metrics.push {
            metric: 'pkgs', order: 3
            current: getValue command, current, true, 'pkgs'
          }

        command.metrics.forEach (metric) ->
          metric.prior = getValue command, prior, (if metric.metric is 'pkgs' then true else false), metric.metric
          metric.delta = metric.current / metric.prior - 1
          return

        return

      resolve result

queries.pkgs =
  # 'package' is a reserved word in JS
  # only want to pull pkgs w/ >= 5 installs, which is around the 3500th pkg sorted by installs
  # hence max-results = 5000
  queryObjs: [
    { # current week
      'ids': 'ga:' + config.ga.profile
      'start-date': '7daysAgo'
      'end-date': 'yesterday'
      'metrics': 'ga:users,ga:pageviews'
      'dimensions': 'ga:pagePathLevel2'
      'filters': 'ga:pagePathLevel1=@installed' # =@ contains substring
      'sort': '-ga:pageviews'
      'max-results': 3500
    }
    { # prior week
      'ids': 'ga:' + config.ga.profile
      'start-date': '14daysAgo'
      'end-date': '8daysAgo'
      'metrics': 'ga:users,ga:pageviews'
      'dimensions': 'ga:pagePathLevel2'
      'filters': 'ga:pagePathLevel1=@installed' # =@ contains substring
      'sort': '-ga:pageviews'
      'max-results': 3500
    }
  ]
  transform: (data) ->
    new rsvp.Promise (resolve, reject) ->
      current = data[0].rows[..19] # TODO: from / to as arg
      prior = data[1].rows[..29]

      _transform = (d, i) ->
        d[0] = util.removeSlash(d[0])
        d[1] = +d[1]; d[2] = +d[2]
        d.push i + 1 # rank
        return
      current.forEach _transform
      prior.forEach _transform

      result = current.map (d) ->
        bName: d[0]
        bRank: current: d[3]
        bUsers: current: d[1] # ga:users
        bInstalls: current: d[2] # ga:pageviews

      ghPromises = []
      result.forEach (pkg) ->
        priorPkg = _find prior, (d) -> d[0] is pkg.bName
        if priorPkg?
          pkg.bRank.prior = priorPkg[3]
          pkg.bUsers.prior = priorPkg[1]
          pkg.bInstalls.prior = priorPkg[2]
        else
          err = new Error "ERROR: no prior period data for package #{ pkg.bName }"
          console.error err
        ghPromises.push gh.appendData pkg
        return

      rsvp.all(ghPromises).then -> resolve result

# ==========

module.exports =
  validQueryTypes: Object.keys queries
  queries: queries
  authPromise: authPromise
  fetch: fetch