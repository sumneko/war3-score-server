local m = {}

local KEY_GROUP  = 'jzslm:speed.group'
local KEY_PLAYER = 'jzslm:speed.player'

local function getGroupUID(players)
    local names = {}
    for _, name in pairs(players) do
        names[#names+1] = ('%q'):format(name)
    end
    table.sort(names)
    return table.concat(names, ',')
end

local function checkGroupRecord(redis, data)
    local uid     = getGroupUID(data.players)
    local newTime = data.time
    local oldTime = tonumber(redis:zscore(KEY_GROUP, uid))
    if oldTime and oldTime <= newTime then
        return {
            result = false,
            old    = oldTime,
            new    = newTime,
        }
    else
        redis:zadd(KEY_GROUP, ('%.3f'):format(newTime), uid)
        return {
            result = true,
            old    = oldTime,
            new    = newTime,
        }
    end
end

local function checkPlayersRecord(redis, data)
    local newTime = data.time
    local results = {}
    for _, player in pairs(data.players) do
        local oldTime = tonumber(redis:hget(KEY_PLAYER, player))
        if oldTime and oldTime <= newTime then
            results[player] = {
                result = false,
                old    = oldTime,
                new    = newTime,
            }
        else
            redis:hset(KEY_PLAYER, player, ('%.3f'):format(newTime))
            results[player] = {
                result = true,
                old    = oldTime,
                new    = newTime,
            }
        end
    end
    return results
end

function m.report(redis, data)
    local groupData = checkGroupRecord(redis, data)
    local playersData = checkPlayersRecord(redis, data)
    return {
        group   = groupData,
        players = playersData,
    }
end

function m.getRank(redis, range)
end

return m
