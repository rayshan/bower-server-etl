url = require 'url'

# ==========

config =
  port: 3000
  apiBaseUri: '/api/1'
  ga:
    clientEmail: '1068634003933-b8cijec64sti0if00mnrbqfnrt7vaa7a@developer.gserviceaccount.com'
    # ask repo owner for GA Service Account key.pem, then export GA_KEY_PATH=path
    privateKeyPath: "/Users/rayshan/=Projects=/2f798d5414685a52456c31158c9fa61fa14256c3-privatekey.pem" # process.env.APP_GA_KEY_PATH || null
    privateKeyContent: process.env.APP_GA_KEY_CONTENT || null
    profile: '75972512'
    scopeUri: 'https://www.googleapis.com/auth/analytics.readonly'

if process.env.NODE_ENV is 'development'
  config.db = '/tmp/redis-stats.bower.io.sock'
else
  config.db = url.parse process.env.REDISCLOUD_URL

module.exports = config