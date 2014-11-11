# Vendor
p = require 'path'
fs = require "fs"
GaExtractor = require 'ga-extractor'

# ==========
_keyContent = if process.env.NODE_ENV is 'production'
    config.ga.privateKeyContent
  else
    fs.readFileSync (p.join __dirname, config.ga.privateKeyPath), ['utf-8']

gaExtractor = new GaExtractor({
  profileId: config.ga.profile
  clientEmail: config.ga.clientEmail
  keyContent: _keyContent
})

# ==========

module.exports = gaExtractor
