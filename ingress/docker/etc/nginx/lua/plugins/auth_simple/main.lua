local ngx = ngx

local _M = {}

function _M.rewrite()
  local auth_header = ngx.var.http_Authorization

  if auth_header == "rejectme" then
    ngx.status = 403
    ngx.say("Token Rejected")
    ngx.exit(ngx.HTTP_FORBIDDEN)
  end
end

return _M
