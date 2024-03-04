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
    local signature_exists, err = red:exists(signature)
    
    -- to confirm connection pooling
    local reused, err = red:get_reused_times()

    ngx.log(ngx.NOTICE, string.format("signature: %s, exists: %d, reused: %d", signature, signature_exists, reused))
    if signature_exists then
        -- return connection to pool
        local ok, err = red:set_keepalive(60000, 5)
          if not ok then
            ngx.log(ngx.WARN, string.format("failed to set keepalive: %s", err))
            return
          end
        end

        -- in lua 0 is truthy so use explicit check for "1"
        if signature_exists == 1 then
          ngx.status = 403
          ngx.say("Token Rejected")
          return ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    end
  end

return _M
