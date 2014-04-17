Flightplan = require 'flightplan'

plan = new Flightplan()

plan.briefing {
  debug: true
  destinations:
    production: [
      {
        host: 'apps.shan.io'
        username: 'ray'
        agent: process.env.SSH_AUTH_SOCK
      }
    ]
}