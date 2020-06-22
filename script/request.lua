local score = require 'script.score'

ngx.req.read_body()
local data = ngx.req.get_body_data()
if data then
    score.test()
    return
end
