# vendor
Promise = require 'bluebird'
_ = require 'lodash-node'
moment = require 'moment'

# custom
config = require "./config"
geo = require "./geo"
gh = require './github'

# ==========

###
# generic GA util
###

util =
  removeSlash: (input) -> input.replace /\//g, '' # remove leading & trailing /

###
# GA query def
###

queries = {}

queries.users =

  queryObj:
    'ids': 'ga:' + config.ga.profile
    'start-date': '2014-03-15'
    'end-date': 'yesterday'
    'metrics': 'ga:users'
    'dimensions': 'ga:userType,ga:date'

  transform: (data) ->
    result = data.rows
    result.forEach (d) ->
      d[0] = if d[0].indexOf('New') isnt -1 then 'N' else 'E'
      d[2] = +d[2]
      return
    result

queries.cmds =

  queryObj:
    'ids': 'ga:' + config.ga.profile
    'start-date': '14daysAgo'
    'end-date': 'yesterday'
    'metrics': 'ga:users,ga:pageviews'
    'dimensions': 'ga:pagePathLevel1,ga:nthWeek'

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

    _transform = (d) ->
      cmdName = util.removeSlash d[0]
      cmdName = cmdName.charAt(0).toUpperCase() + cmdName.slice 1 # Cap Case

      cmd: cmdName
      order: order[cmdName]
      icon: cmdIcons[cmdName]
      metrics: [
        {metric: 'users', order: 1, current: +d[2]} # ga:users
        {metric: 'uses', order: 2, current: +d[3]} # ga:pageviews
      ]

    current = data.rows.filter((d) -> +d[1] is 1).map _transform # current week
    prior = data.rows.filter((d) -> +d[1] is 0).map _transform # previous week

    # remove garbage data from GA e.g. (not set), FakeXMLHttpRequest, Pretender, Route-recognizer...
    garbageFilter = (cmdName) -> cmds.indexOf(cmdName) isnt -1
    edFilter = (cmdName) -> cmdName.indexOf("ed") is -1 # no "-ed"
    result = current.filter (cmdObj) ->
      # console.log "1 = #{garbageFilter cmdObj.cmd}, 2 = #{edFilter cmdObj.cmd}"
      garbageFilter(cmdObj.cmd) and edFilter(cmdObj.cmd)

    getValue = (cmdName, period, ed, valueType) ->
      ed = if ed then 'ed' else ''
      i = if valueType is 'users' then 0 else 1 # ga:users : ga:pageviews
      try # catch edge case in case new cmd tracked and no prior history
        _.find(period, (d) -> d.cmd is cmdName + ed).metrics[i].current
      catch err
        console.error err; 0

    result.forEach (cmd) ->
      # cmd with packages count, i.e. suffixed w/ 'ed'
      if ["Install", "Uninstall", "Register", "Unregister"].indexOf(cmd.cmd) isnt -1
        cmd.metrics.push {
          metric: 'packages', order: 3
          current: getValue cmd.cmd, current, true, 'packages'
        }

      cmd.metrics.forEach (metric) ->
        metric.prior = getValue cmd.cmd, prior, (if metric.metric is 'packages' then true else false), metric.metric
        metric.delta = metric.current / metric.prior - 1
        return

      return

    result

queries.packages =
  # 'package' is a reserved word in JS
  # only want to pull packages w/ >= 5 installs, which is around the 3500th pkg sorted by installs

  queryObj:
    'ids': 'ga:' + config.ga.profile
    'dimensions': 'ga:pagePathLevel2,ga:nthDay'
    'metrics': 'ga:pageviews'
    'filters': 'ga:pagePathLevel1=@installed;ga:pageviews>=100'
    'start-date': '14daysAgo'
    'end-date': 'yesterday'
    # =@ contains substring, don't use url encoding '%3D@'; test for specific pkg, add ;ga:pagePathLevel2==/video.js/ (; = AND)
    # 'sort': '-ga:pageviews'
    # 'max-results': 100 # desired result quantity * 2 due to ga:nthWeek dim doubling # of rows returned

  transform: (data) ->
    # TODO: ranking range as arg

    dataNested = _.groupBy data.rows, (d) -> d[0]
    data = Object.keys(dataNested).map (name) ->
      # extract daily install counts to an array
      installs = []
      dataNested[name].forEach (d) -> installs[+d[1]] = +d[2]; return
      # ensure array has 14 days of data
      installs = [0..13].map (i) -> if installs[i] then installs[i] else 100

      name: util.removeSlash name
      installs: installs

    sortFunc = (period, currentOrPrior) -> (a, b) ->
      reduceFunc = (a, b, i) ->
        if (if currentOrPrior is 'current' then i >= period else i < period) then a + b else a
      (b.installs.reduce reduceFunc, 0) - (a.installs.reduce reduceFunc, 0)

    # find prior period rankings
    data.sort sortFunc 7, 'prior'
    data.forEach (d, i) -> d.rank = []; d.rank.push i + 1
    # find current period rankings
    data.sort sortFunc 7, 'current'
    data.forEach (d, i) -> d.rank.push i + 1

    ghPromises = []
    data.forEach (pkg) -> ghPromises.push gh.appendData pkg; return
    Promise.all(ghPromises).then -> data

queries.geo =

  queryObj:
    # monthly active users
    'ids': 'ga:' + config.ga.profile
    'start-date': '30daysAgo'
    'end-date': 'yesterday'
    'metrics': 'ga:users'
    'dimensions': 'ga:country'
    'sort': '-ga:users'

  transform: (data) ->
    geoPromises = []

    # remove (not set) country & country w/ just 1 user
    current = data.rows.filter (country) ->
      country[0] isnt "(not set)" and +country[1] > 1

    result = current.map (d) ->
      name: d[0]
      isoCode: geo.getCode d[0] # get ISO 3166-1 alpha-3 code
      users: +d[1]

    result.forEach (country) ->
      geoPromise = geo.getPop(country.isoCode).then (pop) ->
        country.density = Math.ceil(country.users / pop * 1000000) # per 1mil
        return
      # get population from world bank api then calc bower user density per 1m pop
      geoPromises.push geoPromise
      return

    Promise.all geoPromises
      .call 'sort', (a, b) -> b.density - a.density
      .then -> result

module.exports = queries