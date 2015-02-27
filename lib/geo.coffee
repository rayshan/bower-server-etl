# vendor
fs = require 'fs'
p = require 'path'

_ = require 'lodash-node'
Promise = require 'bluebird'
csvParseAsync = Promise.promisify require 'csv-parse'

# custom
codeMapping = require 'geoCodeMapping'

# ==========
# load & parse internet user data csv

csvParserOptions = skipEmptyLines: true, trim: true, auto_parse: true
csvDataFile = fs.readFileSync p.join __dirname, '../data/geoInternetUsers.csv'
loadPopData = csvParseAsync csvDataFile, csvParserOptions
  .then (data) ->
    data.forEach (d) -> d.splice 2, d.length
    data

# ==========
# get ISO 3166-1 alpha-3 code given GA's full country name

getCode = (name) ->
  try _.find(codeMapping, (d) -> d.name is name)["alpha-3"]
  catch error
    err = new Error "'#{ name }' not found in ISO 3166-1 alpha-3 codeMapping; err = #{ error }."
    console.error err # can't throw here b/c sync
    "N/A"

# ==========
getPop = (code) ->
  loadPopData.then (data) ->
    try (_.find data, (d) -> d[0] is code)[1]
    catch err
      throw new Error "[#{code}] has no internet user data in csv file."

# ==========
module.exports =
  getCode: getCode
  getPop: getPop # async
