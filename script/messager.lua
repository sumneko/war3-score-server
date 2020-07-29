local proto = require 'script.proto.proto'
local zero  = require 'script.proto.zero'

local m = {}

function m.recive()
    ngx.req.read_body()
    local stream = ngx.req.get_body_data()
    if not stream then
        ngx.log(ngx.ERR, '没有收到数据？')
        return nil
    end

    local suc, zstream = pcall(zero.decode, stream)
    if not suc then
        ngx.log(ngx.ERR, zstream, ('%q'):format(stream))
        return nil
    end
    local suc, data = pcall(proto.decode, zstream)
    if not suc then
        ngx.log(ngx.ERR, data, ('%q'):format(zstream))
        return
    end

    return data
end

function m.response(data)
    local rstream = zero.encode(proto.encode(data))
    ngx.print(rstream)
end

return m
