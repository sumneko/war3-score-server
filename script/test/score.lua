local m = {}

function m.test(red, data)
    local ok, err = red:incrby('test', 10)
    if not ok then
        ngx.say(err)
        return
    end

    ngx.say('test = ', red:get('test'))
end

function m.ping(red, data)
    return {
        type  = 'pong',
        value = ('hello %s!'):format(data.value),
    }
end

function m.hello(red, data)
    local ip = ngx.var.remote_addr
    red:zincrby('hello', 1, ip)
    local count = red:zscore('hello', ip)
    local max = 10
    local list = red:zrevrange('hello', 0, max-1, 'WITHSCORES')
    local lines = {}
    lines[#lines+1] = '======= 排行榜 ======='
    for i = 1, max do
        local name = list[i * 2 - 1]
        local score = list[i * 2]
        if not name then
            break
        end
        lines[#lines+1] = ('%d. %s: 连接了 %s 次'):format(i, name, score)
    end
    lines[#lines+1] = '==================='

    return ('你好，来自 %s 的 %s ，你已成功连接服务器。这是你的第 %d 次连接。\n%s'):format(ip, data.source, count, table.concat(lines, '\n'))
end

return m
