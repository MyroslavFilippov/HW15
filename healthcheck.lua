local http = require "resty.http"

local function check_server(host, port)
    local httpc = http.new()
    local ok, err = httpc:connect(host, port)
    if not ok then
        return false
    end
    httpc:set_keepalive()
    return true
end

local function health_check()
    local uk_ok = check_server("uk_server", 80)
    local us1_ok = check_server("us_server1", 80)
    local us2_ok = check_server("us_server2", 80)
    local other_ok = check_server("other_server", 80)
    local backup_ok = check_server("backup_server", 80)

    if not (uk_ok and us1_ok and us2_ok and other_ok) then
        ngx.status = 500
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    ngx.status = 200
    ngx.exit(ngx.HTTP_OK)
end

local function health_check_timer(premature)
    if not premature then
        health_check()
        local ok, err = ngx.timer.at(5, health_check_timer)
        if not ok then
            ngx.log(ngx.ERR, "failed to create timer: ", err)
            return
        end
    end
end

local ok, err = ngx.timer.at(0, health_check_timer)
if not ok then
    ngx.log(ngx.ERR, "failed to create initial timer: ", err)
    return
end
