# Vendor
Promise = require 'bluebird'
gapi = require "googleapis"
_find = require 'lodash-node/modern/collections/find' # to be replaced w/ array.prototype.find w/ node --harmony
gh = require './github'

# Custom
config = require "./config"
geo = require "./geo"

# ==========

###
# generic GA util
###

util =
  removeSlash: (input) -> input.replace /\//g, '' # remove leading & trailing /

# define auth obj; used for init auth & fetches
authClient = new gapi.auth.JWT(
  config.ga.clientEmail,
  if process.env.NODE_ENV is 'development' then config.ga.privateKeyPath else null, # key as .pem file
  if process.env.NODE_ENV is 'production' then config.ga.privateKeyContent else null,
  [config.ga.scopeUri]
)

# auth on bootstrap
authPromise = new Promise (resolve, reject) ->
  console.log "[INFO] OAuthing w/ GA..."
  authClient.authorize (err, token) ->
    # returns expires_in: 1395623939 and refresh_token: 'jwt-placeholder', not sure if 16 days or 44 yrs -_-
    if err
      error = new Error "[ERROR] OAuth error; err = #{ err }"
      reject error
    else
      console.info "[SUCCESS] server OAuthed w/ GA."
      gapi.discover('analytics', 'v3').withAuthClient(authClient).execute (err, client) ->
        if err
          error = new Error "[ERROR] gapi.discover.execute, err = #{ err }"
          reject error
        else resolve client # reuse this client
        return
    return
  return

fetch = (key) ->
  (client) -> # client returned from gapi.discover.execute
    query = queries[key]
    queryPromises = []

    query.queryObjs.forEach (queryObj) ->
      promise = new Promise (resolve, reject) ->
        client.analytics.data.ga.get(queryObj).execute (err, result) ->
          if err
            error = new Error "[ERROR] client.analytics.data.ga.get, err = #{ err.message }"
            reject error
          else resolve result
          return
        return
      queryPromises.push promise
      return

    Promise.all(queryPromises).then query.transform
    # err catched in cache.coffee .catch (err) -> console.error err; return

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
#    console.log "transforming users"
#    console.log data[0].rows[1]

    result = data[0].rows
    result.forEach (d) ->
      d[0] = if d[0].indexOf('New') != -1 then 'N' else 'E'
      d[2] = +d[2]
      return
    result

queries.cmds =
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
    cmdIcons = # define font awesome icons
      Install: 'download'
      Installed: null
      Uninstall: 'trash-o'
      Uninstalled: null
      Register: 'pencil'
      Registered: null
      Unregister: 'eraser'
      Info: 'info'
      Search: 'search'
    cmds = Object.keys cmdIcons
    # set order for display
    order = {}
    cmds.forEach (cmd, i) -> order[cmd] = i; return

    current = data[0].rows
    prior = data[1].rows

    _transform = (d) ->
      cmdName = util.removeSlash d[0]
      cmdName = cmdName.charAt(0).toUpperCase() + cmdName.slice 1 # Cap Case
      d[0] = cmdName
      d[1] = +d[1]
      d[2] = +d[2]
      return
    current.forEach _transform
    prior.forEach _transform

    # remove garbage data from GA e.g. (not set), FakeXMLHttpRequest, Pretender, Route-recognizer...
    current = current.filter (cmd) -> cmds.indexOf(cmd[0]) isnt -1

    cmdCheck = (d) -> d[0].indexOf("ed") is -1 # and d[0] != "Searched"
    # keep only cmds that isn't called on success; 'Searched' is deprecated
    result = current.filter (d) -> cmdCheck d
      .map (d) ->
        cmd: d[0]
        order: order[d[0]]
        icon: cmdIcons[d[0]]
        metrics: [
          {metric: 'users', order: 1, current: d[1]} # ga:users
          {metric: 'uses', order: 2, current: d[2]} # ga:pageviews
        ]

    getValue = (cmd, period, ed, valueType) ->
      ed = if ed then 'ed' else ''
      i = if valueType is 'users' then 1 else 2 # else pkgs
      # catch edge case in case new cmd tracked and no prior history
      try
        _find(period, (d) -> d[0] is cmd.cmd + ed)[i]
      catch error
        0 # if not found, cmd tracking wasn't implemented

    result.forEach (cmd) ->
      # cmd with pkgs count ('-ed')
      if ["Install", "Uninstall", "Register", "Unregister"].indexOf(cmd.cmd) != -1
        cmd.metrics.push {
          metric: 'pkgs', order: 3
          current: getValue cmd, current, true, 'pkgs'
        }

      cmd.metrics.forEach (metric) ->
        metric.prior = getValue cmd, prior, (if metric.metric is 'pkgs' then true else false), metric.metric
        metric.delta = metric.current / metric.prior - 1
        return

      return

    result

queries.pkgs =
  # 'package' is a reserved word in JS
  # only want to pull pkgs w/ >= 5 installs, which is around the 3500th pkg sorted by installs
  queryObjs: [
    { # current week
      'ids': 'ga:' + config.ga.profile
      'start-date': '7daysAgo'
      'end-date': 'yesterday'
      'metrics': 'ga:users,ga:pageviews'
      'dimensions': 'ga:pagePathLevel2'
      'filters': 'ga:pagePathLevel1=@installed' # =@ contains substring, don't use url encoding '%3D@'
      'sort': '-ga:pageviews'
      'max-results': 3500
    }
    { # prior week
      'ids': 'ga:' + config.ga.profile
      'start-date': '14daysAgo'
      'end-date': '8daysAgo'
      'metrics': 'ga:users,ga:pageviews'
      'dimensions': 'ga:pagePathLevel2'
      'filters': 'ga:pagePathLevel1=@installed'
      'sort': '-ga:pageviews'
      'max-results': 3500
    }
  ]
  transform: (data) ->
    current = data[0].rows[..19] # TODO: ranking range as arg
    prior = data[1].rows[..29]

    _transform = (d, i) ->
      d[0] = util.removeSlash d[0]
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
        error = new Error "[ERROR] no prior period data for package #{ pkg.bName }"
        console.error error
      ghPromises.push gh.appendData pkg
      return

    Promise.all(ghPromises).then -> result

queries.geo =
  queryObjs: [
    { # monthly active users
      'ids': 'ga:' + config.ga.profile
      'start-date': '30daysAgo'
      'end-date': 'yesterday'
      'metrics': 'ga:users'
      'dimensions': 'ga:country'
      'sort': '-ga:users'
    }
  ]
  transform: (data) ->
    current = data[0].rows
    geoPromises = []

    # remove (not set) country & country w/ just 1 user
    current = current.filter (country) ->
      country[0] != "(not set)" and +country[1] > 1

    result = current.map (d) ->
      name: d[0]
      isoCode: geo.getCode d[0] # get ISO 3166-1 alpha-3 code
      users: +d[1]

    result.forEach (country) ->
      geoPromise = geo.getPop(country.isoCode).then (pop) ->
        country.density = Math.ceil(country.users / pop * 1000000)
        return
      # get population from world bank api then calc bower user density per 1m pop
      geoPromises.push geoPromise
      return

    Promise.all geoPromises
      .call 'sort', (a, b) -> b.density - a.density
      .then -> result

# ==========

module.exports =
  validQueryTypes: Object.keys(queries).concat 'overview'
  queries: queries
  authPromise: authPromise
  fetch: fetch