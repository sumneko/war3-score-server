local score = require 'script.score'
local proto = require 'script.proto.proto'
local zero  = require 'script.proto.zero'

ngx.req.read_body()
local stream = ngx.req.get_body_data()
if not stream then
    ngx.log(ngx.ERR, '没有收到数据？')
    return
end

local suc, zstream = pcall(zero.decode, stream)
if not suc then
    ngx.log(ngx.ERR, zstream, ('%q'):format(stream))
    return
end
local suc, data = pcall(proto.decode, zstream)
if not suc then
    ngx.log(ngx.ERR, data, ('%q'):format(zstream))
    return
end


local response
if data.type == 'ping' then
    response = score.ping(data)
elseif data.type == 'hello' then
    response = score.hello(data)
else
    response = ('Unkown Data Type: %s'):format(data.type)
end

local rstream = zero.encode(proto.encode(response))
ngx.print(rstream)
