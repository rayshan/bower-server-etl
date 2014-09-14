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
      host: process.env.DB_DEV_HOST
      port: process.env.DB_DEV_PORT
      username: process.env.DB_DEV_USER
      password: process.env.DB_DEV_PASSWORD
      database: process.env.DB_DEV_DATABASE
      dialect: process.env.DB_DEV_DIALECT
    cache: '/tmp/redis-stats.bower.io.sock'

  production:
    port: 3000
    apiBaseUri: '/api/1'
    ga:
      clientEmail: process.env.APP_GA_CLIENT_EMAIL
      privateKeyContent: process.env.APP_GA_KEY_CONTENT
      profile: '75972512'
      scopeUri: 'https://www.googleapis.com/auth/analytics.readonly'
    db:
      host: process.env.DB_PROD_HOST
      port: process.env.DB_PROD_PORT
      username: process.env.DB_PROD_USER
      password: process.env.DB_PROD_PASSWORD
      database: process.env.DB_PROD_DATABASE
      dialect: process.env.DB_PROD_DIALECT
    cache: url.parse process.env.REDISCLOUD_URL

module.exports = config
