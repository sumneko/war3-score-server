local score = require 'script.score'

ngx.req.read_body()  -- explicitly read the req body
local data = ngx.req.get_body_data()
if data then
    ngx.say("body data:")
    ngx.print(data)
    return
end
