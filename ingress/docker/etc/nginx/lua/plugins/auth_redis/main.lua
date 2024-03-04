local ngx = ngx

local redis = require "resty.redis"

local _M = {}

function _M.rewrite()
  local red = redis:new()

  local ok, err = red:connect("redis.ingress.svc.cluster.local", 6379, { pool_size=5 })

  if not ok then
      ngx.say("failed to connect: ", err)
      return
  end

  local auth_header = ngx.var.http_Authorization
  local signature
  if auth_header then
      signature = string.match(auth_header, "Bearer%s+.*%.(.+)")
  end

  if signature then
    local reused, err = red:get_reused_times()

    local res, err = red:exists(signature)
    ngx.log(ngx.NOTICE, string.format("signature: %s, exists: %d, reused: %d", signature, res, reused))
    if res then
        -- in lua 0 is truthy so use explicit check for "1"
        if res == 1 then
          ngx.status = 403
          ngx.say("Token Rejected")
          ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    end
  end

  -- put it into the connection pool of size 5,
  -- with 60 seconds max idle time
  local ok, err = red:set_keepalive(60000, 5)
  if not ok then
    ngx.log(ngx.WARN, string.format("failed to set keepalive: %s", err))
    return
  end
end


return _M
