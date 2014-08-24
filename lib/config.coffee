url = require 'url'

# ==========

# ask repo owner for GA Service Account key.pem & foreman .env file; place into project root

config =
  development:
    port: 3000
    apiBaseUri: '/api/1'
    ga:
      clientEmail: process.env.APP_GA_CLIENT_EMAIL
      privateKeyPath: "../gaServiceAcctKeyDev.pem"
      profile: '75972512'
      scopeUri: 'https://www.googleapis.com/auth/analytics.readonly'
    db:
      host: 'localhost'
      port: 5432
      username: process.env.DB_DEV_USER
      password: process.env.DB_DEV_PASSWORD
      database: process.env.DB_DEV_DATABASE
    cache: '/tmp/redis-stats.bower.io.sock'

  production:
    port: 3000
    apiBaseUri: '/api/1'
    ga:
      clientEmail: process.env.APP_GA_CLIENT_EMAIL
      privateKeyContent: process.env.APP_GA_KEY_CONTENT
      profile: '75972512'
      scopeUri: 'https://www.googleapis.com/auth/analytics.readonly'
    db: null
    cache: url.parse process.env.REDISCLOUD_URL

module.exports = config
