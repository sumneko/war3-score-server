local score = require 'script.score'
local proto = require 'script.proto'

ngx.req.read_body()
local stream = ngx.req.get_body_data()
if not stream then
    return
end

local suc, data = pcall(proto.decode, stream)
if not suc then
    return
end

local response
if data.type == 'ping' then
    response = score.ping(data)
end

local rstream = proto.encode(response)
ngx.say(rstream)
