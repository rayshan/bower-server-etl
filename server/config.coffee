config =
  ga:
    clientEmail: "1068634003933-b8cijec64sti0if00mnrbqfnrt7vaa7a@developer.gserviceaccount.com"
    # ask repo owner for GA Service Account key.pem, then export GA_KEY_PATH=path
    privateKeyPath: process.env.APP_GA_KEY_PATH || null
    profile : "75972512"
    scopeUri : "https://www.googleapis.com/auth/analytics.readonly"
  db:
    socket: '/tmp/redis.sock'

module.exports = config