# Shared Redis connection used for real-time presence tracking.
# The connection is established lazily by redis-rb, so requiring this file does
# not open a socket at boot.
TEAMSYNC_REDIS = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))
