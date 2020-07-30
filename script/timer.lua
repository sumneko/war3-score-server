local m = {}

m._tickList = {}

function m.onTick(callback)
    m._tickList[#m._tickList+1] = callback
end

function m._updateTicks()
    for _, callback in ipairs(m._tickList) do
        local suc, err = xpcall(callback, debug.traceback)
        if not suc then
            ngx.log(ngx.ERR, err)
        end
    end
end

function m.update()
    m._updateTicks()
end

return m
