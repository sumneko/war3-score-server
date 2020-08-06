local async = io.open('script/jzslm/hotfix/async.lua'):read '*a'

return function (rds, data)
    --if data.name == '决战苏拉玛 1.2.4' then
        return {
            async = async,
        }
    --end
    --return {}
end
