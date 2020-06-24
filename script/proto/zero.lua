local function encodeStr(buf, str)
    local index = 1
    while true do
        local len = #str - index + 1
        if len <= 0xf then
            buf[#buf+1] = ('%X%s'):format(len, str:sub(index))
            break
        end
        buf[#buf+1] = 'F'
        buf[#buf+1] = str:sub(index, index + 0xe)
        buf[#buf+1] = '0'
        index = index + 0xf
    end
end

local function encodeLen(buf, len)
    while true do
        if len <= 0xf then
            buf[#buf+1] = ('%X'):format(len)
            break
        end
        len = len - 0xf
        buf[#buf+1] = 'F0'
    end
end

local function encode(dump)
    local buf = {}
    local index = 1
    while true do
        local start, finish = dump:find('%z+', index)
        if not start then
            if index <= #dump then
                local str = dump:sub(index)
                encodeStr(buf, str)
            end
            break
        end
        local len = finish - start + 1
        local str = dump:sub(index, start - 1)
        encodeStr(buf, str)
        encodeLen(buf, len)
        index = finish + 1
    end

    return table.concat(buf)
end

local function decode(stream)
    local buf = {}
    local index = 1
    while index <= #stream do
        local len = tonumber(stream:sub(index, index), 16)
        index = index + 1
        buf[#buf+1] = stream:sub(index, index + len - 1)
        index = index + len
        if index > #stream then
            break
        end
        local n = tonumber(stream:sub(index, index), 16)
        buf[#buf+1] = ('\0'):rep(n)
        index = index + 1
    end
    return table.concat(buf)
end


return {
    encode = encode,
    decode = decode,
}
