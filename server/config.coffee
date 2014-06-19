url = require 'url'

# ==========

config =
  port: 3000
  apiBaseUri: '/api/1'
  ga:
    clientEmail: '1068634003933-hgpd424gtchnb0f6ikfn7rkc5q6toubg@developer.gserviceaccount.com'
    # ask repo owner for GA Service Account key.pem, then export GA_KEY_PATH=path
    privateKeyPath: "../gaServiceAcctKeyDev.pem" # for dev
    privateKeyContent: process.env.APP_GA_KEY_CONTENT # for prod
    profile: '75972512'
    scopeUri: 'https://www.googleapis.com/auth/analytics.readonly'

if process.env.NODE_ENV is 'development'
  config.db = '/tmp/redis-stats.bower.io.sock'
else
  config.db = url.parse process.env.REDISCLOUD_URL

module.exports = config