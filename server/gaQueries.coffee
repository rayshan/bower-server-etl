# vendor
Promise = require 'bluebird'
_ = require 'lodash-node'
moment = require 'moment'
#pj = require('prettyjson').render

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

queries.commands =

  queryObj:
    'ids': 'ga:' + config.ga.profile
    'dimensions': 'ga:pagePathLevel1,ga:nthDay'
    'metrics': 'ga:users,ga:pageviews'
    'start-date': '14daysAgo'
    'end-date': 'yesterday'
    'sort': 'ga:nthDay'

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
    commands = Object.keys cmdIcons
    # set order for display
    order = {}
    commands.forEach (cmd, i) -> order[cmd] = i; return

    # reformat command name
    data.rows.forEach (d) ->
      cmdName = util.removeSlash d[0]
      cmdName = cmdName.charAt(0).toUpperCase() + cmdName.slice 1 # Cap Case
      d[0] = cmdName
      return

    # remove garbage data from GA e.g. (not set), FakeXMLHttpRequest, Pretender, Route-recognizer...
    data = data.rows.filter (d) -> commands.indexOf(d[0]) isnt -1

    # filter for current data
    dataCurrent = data.filter (d) -> d[0].indexOf("ed") is -1 # no "-ed"
    dataCurrent = _.groupBy dataCurrent, (d) -> d[0]

    # filter for prior data
    dataPrior = data.filter (d) -> d[0].indexOf("ed") isnt -1
    dataPrior = _.groupBy dataPrior, (d) -> d[0]

    # construct model schema
    result = Object.keys(dataCurrent).map (name) -> # can't use _.mapValues due to want an arr in the end
      # extract daily install counts to an array
      users = []
      uses = []
      dataCurrent[name].forEach (d) ->
        # i1 = day, i2 = users, i3 = uses / packages
        users[+d[1]] = +d[2]
        uses[+d[1]] = +d[3]
        return

      name: name
      order: order[name]
      icon: cmdIcons[name]
      users: users
      uses: uses

    # append successful package numbers to commands with packages count, i.e. suffixed w/ 'ed'
    result.forEach (cmdObj) ->
      if ["Install", "Uninstall", "Register", "Unregister"].indexOf(cmdObj.name) isnt -1
        packages = []
        edName = cmdObj.name + 'ed'
        try
          dataPrior[edName].forEach (d) -> packages[+d[1]] = +d[3]; return
        catch err
          console.error err
        cmdObj.packages = packages
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

    # TODO: force cache only top 100; to be removed
    data.splice 100

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