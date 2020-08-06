local jass   = require 'jass.common'
local japi   = require 'jass.japi'
local record = require 'ac.record'

local function reportCheat()
    print('作弊')
    record.request('common', 'cheat', {
        ['player'] = ac.localPlayer():userName(),
        ['value']  = 10,
    })
end

local function getAttackSpeed(u)
    local v = u:get '攻击速度'
    if v >= 0 then
        return 1 + v / 100
    else
        --当攻击速度小于0的时候,每点相当于攻击间隔增加1%
        return 1 + v / (100 - v)
    end
end

ac.loop(10, function ()
    local u = ac.localSelectedUnit()
    if not u then
        return
    end
    if u:getOwner() ~= ac.localPlayer() then
        return
    end
    -- 检查无敌
    if not u:hasRestriction '无敌' and jass.GetUnitAbilityLevel(u._handle, ac.id['Avul']) > 0 then
        reportCheat()
        return
    end
    -- 检查攻击间隔
    if math.abs(u:get '攻击间隔' - japi.GetUnitState(u._handle, 0x25)) > 0.01 then
        reportCheat()
        return
    end
    -- 检查攻击速度
    if math.abs(getAttackSpeed(u) - japi.GetUnitState(u._handle, 0x51)) > 0.01 then
        reportCheat()
        return
    end
    -- 检查攻击范围
    if math.abs(u:get '攻击范围' - japi.GetUnitState(u._handle, 0x16)) > 0.01 then
        reportCheat()
        return
    end
end)
