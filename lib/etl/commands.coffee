# vendor
_ = require 'lodash-node'
Promise = require 'bluebird'

# custom
util = require "bUtil"
gaExtractor = require "googleAnalytics"
cache = require "cache"

# ==========

etl = {}
etl.name = 'commands'
etl.gaQueryObj =
  'dimensions': 'ga:pagePathLevel1,ga:nthDay'
  'metrics': 'ga:users,ga:pageviews'
  'start-date': '15daysAgo'
  'end-date': '2daysAgo'
  'sort': 'ga:pagePathLevel1,ga:nthDay'

etl.extract = ->
  util.etlLogger 'extract', @name
  gaExtractor.extract @gaQueryObj

etl.transform = (data) ->
  util.etlLogger 'transform', @name

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
  data.forEach (d) ->
    cmdName = util.removeSlash d[0]
    cmdName = cmdName.charAt(0).toUpperCase() + cmdName.slice 1 # Cap Case
    d[0] = cmdName
    return

  # remove garbage data from GA e.g. (not set), FakeXMLHttpRequest, Pretender, Route-recognizer...
  data = data.filter (d) -> commands.indexOf(d[0]) isnt -1

  # filter for current data
  dataCurrent = data.filter (d) -> d[0].indexOf("ed") is -1 # no "-ed"
  dataCurrent = _.groupBy dataCurrent, (d) -> d[0]

  # filter for prior data
  dataPrior = data.filter (d) -> d[0].indexOf("ed") isnt -1
  dataPrior = _.groupBy dataPrior, (d) -> d[0]

  # construct etl schema
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

etl.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

module.exports = etl
