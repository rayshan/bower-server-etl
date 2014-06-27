# Vendor
_ = require 'lodash-node' # to be replaced w/ array.prototype.find w/ node --harmony
Promise = require 'bluebird'
request = Promise.promisifyAll require 'request'

# custom

codeMapping = require './geoCodeMapping'

# ==========

# not in world bank data, manual entry
popByCode =
  GIB: 30001
  ALA: 28666
  GUF: 250109
  REU: 840974
  MTQ: 386486
  TWN: 23373517
  MKD: 2058539
  XKX: 1900000
  BES: 21133
  GGY: 65345
  JEY: 97857
  GLP: 405739

# get ISO 3166-1 alpha-3 code given full country name
getCode = (name) ->
  try _.find(codeMapping, (d) -> d.name is name)["alpha-3"]
  catch error
    err = new Error "[ERROR] '#{ name }' not found in ISO 3166-1 alpha-3 codeMapping; err = #{ error }."
    console.error err
    "N/A"

# async get country population from World Bank API given ISO 3166-1 alpha-3 code
getPop = (code) ->
#  if code is "N/A" then resolve 0 else
  wbIndicator = "SP.POP.TOTL"
  wbYr = 2012
  wbEndpoint = "http://api.worldbank.org/countries/#{ code }/indicators/#{ wbIndicator }?format=json&date=#{ wbYr }"
  # e.g. http://api.worldbank.org/countries/usa/indicators/SP.POP.TOTL?format=json&date=2012

  request.getAsync wbEndpoint
    .spread (res, body) ->
      try JSON.parse(body)[1][0].value
      catch err
        if popByCode.hasOwnProperty code
          popByCode[code]
        else
          console.error new Error "[ERROR] alpha-3 code '#{ code }' not found in world bank api or manual entry; err = #{ err }."
          0

module.exports =
  getCode: getCode
  getPop: getPop # async