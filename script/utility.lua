local m = {}

function m.zrange(redis, key, start, finish)
    if start > 0 then
        start = start - 1
    end
    if finish > 0 then
        finish = finish - 1
    end
    local list = redis:zrange(key, start, finish, 'WITHSCORES')
    local fields = {}
    local scores = {}
    for i = 1, finish - start + 1 do
        local field = list[i * 2 - 1]
        local score = list[i * 2]
        if not field then
            break
        end
        fields[i] = field
        scores[i] = score
    end
    return fields, scores
end

function m.zrevrange(redis, key, start, finish)
    if start > 0 then
        start = start - 1
    end
    if finish > 0 then
        finish = finish - 1
    end
    local list = redis:zrevrange(key, start, finish, 'WITHSCORES')
    local fields = {}
    local scores = {}
    for i = 1, finish - start + 1 do
        local field = list[i * 2 - 1]
        local score = list[i * 2]
        if not field then
            break
        end
        fields[i] = field
        scores[i] = score
    end
    return fields, scores
end

function m.zrevrangebyscore(redis, key, max, min)
    local list = redis:zrevrangebyscore(key, max, min, 'WITHSCORES')
    local fields = {}
    local scores = {}
    for i = 1, min - max + 1 do
        local field = list[i * 2 - 1]
        local score = list[i * 2]
        if not field then
            break
        end
        fields[i] = field
        scores[i] = score
    end
    return fields, scores
end

function m.unpackList(buf)
    local f = assert(loadstring('return' .. buf))
    return {f()}
end

function m.packList(t, unique)
    local l = {}
    for i = 1, #t do
        local buf = ('%q'):format(t[i])
        if not unique or not l[buf] then
            l[i] = buf
            l[buf] = true
        end
    end
    if unique then
        table.sort(l)
    end
    return table.concat(l, ',')
end

return m
