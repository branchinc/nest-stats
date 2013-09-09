Q = require 'q'

class StatsClient
  constructor: (options) ->
    @stathat = options.stathat
    @stathatEmail = options.stathatEmail
    @redis = options.redis
    @env = options.env

  incr: (stat) ->
    if @env == 'production'
      @stathat.trackEZCount(@stathatEmail, stat, 1, ->)
    else
      @debug(stat)

  value: (stat, value) ->
    if @env == 'production'
      @stathat.trackEZValue(@stathatEmail, stat, value, ->)
    else if @env == 'development'
      @debug(stat, value)

  time: (stat, future) ->
    startTime = new Date()

    Q(future).then (result) =>
      @value(stat, new Date() - startTime)
      result

  incrOnce: (stat, value) ->
    day = Date.create("0:00:00-04:00").valueOf() / 1000
    redisKey = "stats:incr_once:#{stat}:#{day}"

    @redis.q.sismember(redisKey, value).then (isMember) =>
      unless isMember
        @incr(stat)
        @redis.q.sadd(redisKey, value)
        @redis.q.expire(redisKey, 86400)

  debug: (stat, value) ->
    if process.env.DEBUG
      if value then console.log(stat, value) else console.log(stat)


module.exports = StatsClient
