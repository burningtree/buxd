module.exports = (app, bux) ->

  get: (reply) ->
    bux.performance (err, data) ->
      reply data 

