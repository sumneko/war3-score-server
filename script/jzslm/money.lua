local timer = require 'script.timer'
local redis = require 'script.redis'
local util  = require 'script.utility'
local KEY   = require 'script.jzslm.key'

local function unpackList(buf)
    local f = assert(loadstring('return' .. buf))
    return {f()}
end

local function doAward(red, state, min, max, award)
    if not state.mark then
        state.mark = {}
    end
    local uids, times = util.zrange(red, KEY)
end

local function checkAward(time, date)
    if date.hour == 23 and date.min == 50 and date.sec == 0 then
        local state = {}
        redis.call(doAward, state, 001, 001, 100)
        redis.call(doAward, state, 002, 002, 064)
        redis.call(doAward, state, 003, 003, 047)
        redis.call(doAward, state, 004, 010, 035)
        redis.call(doAward, state, 011, 100, 028)
        redis.call(doAward, state, 101, 500, 023)
        redis.call(doAward, state, 501, -01, 020)
    end
end

timer.onTick(function ()
    checkAward()
end)
