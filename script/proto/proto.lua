local lpack = require 'lpack'

for k, v in pairs(lpack) do
    string[k] = v
end

local TYPE = {
    TRUE     = 'T',
    FALSE    = 'F',
    INT0     = '0',
    INT      = 'I',
    FLOAT0   = '.',
    FLOAT    = '*',
    STRING   = 'S',
    TABLES   = '{',
    TABLEF   = '}',
    UNIT     = 'U',
    POINT    = 'P',
    FUNCTION = 'C',
}

local encodeValue, decodeValue

local function encodeBoolean(buf, b)
    if b then
        buf[#buf+1] = TYPE.TRUE
    else
        buf[#buf+1] = TYPE.FALSE
    end
end

local function encodeNumber(buf, n)
    if math.type(n) == 'integer' then
        if n == 0 then
            buf[#buf+1] = TYPE.INT0
            return
        end
        buf[#buf+1] = ('c1i4'):pack(TYPE.INT, n)
    else
        if n == 0.0 then
            buf[#buf+1] = TYPE.FLOAT0
            return
        end
        buf[#buf+1] = ('c1f'):pack(TYPE.FLOAT, n)
    end
end

local function encodeString(buf, s)
    buf[#buf+1] = ('c1s2'):pack(TYPE.STRING, s)
end

local function encodeTable(buf, t)
    buf[#buf+1] = TYPE.TABLES
    for k, v in next, t do
        encodeValue(buf, k)
        encodeValue(buf, v)
    end
    buf[#buf+1] = TYPE.TABLEF
end

local function encodeFunction(buf, f)
    for i = 1, 100 do
        local name = debug.getupvalue(f, i)
        if not name then
            break
        end
        if name ~= '_ENV' then
            error('传递函数不能包含任何上值：' .. name)
            return
        end
    end
    local stream = string.dump(f)
    buf[#buf+1] = ('c1s2'):pack(TYPE.FUNCTION, stream)
end

function encodeValue(buf, o)
    local tp = type(o)
    if tp == 'boolean' then
        encodeBoolean(buf, o)
    elseif tp == 'number' then
        encodeNumber(buf, o)
    elseif tp == 'string' then
        encodeString(buf, o)
    elseif tp == 'table' then
        encodeTable(buf, o)
    elseif tp == 'function' then
        encodeFunction(buf, o)
    end
end

function decodeValue(stream, index)
    local ot = stream:sub(index, index)
    index = index + 1
    if ot == TYPE.TRUE then
        return true, index
    elseif ot == TYPE.FALSE then
        return false, index
    elseif ot == TYPE.INT0 then
        return 0, index
    elseif ot == TYPE.INT then
        return ('i4'):unpack(stream, index)
    elseif ot == TYPE.FLOAT0 then
        return 0.0, index
    elseif ot == TYPE.FLOAT then
        return ('f'):unpack(stream, index)
    elseif ot == TYPE.STRING then
        return ('s2'):unpack(stream, index)
    elseif ot == TYPE.TABLES then
        local t = {}
        local k, v
        while stream:sub(index, index) ~= TYPE.TABLEF do
            k, index = decodeValue(stream, index)
            v, index = decodeValue(stream, index)
            if k ~= nil then
                t[k] = v
            end
        end
        return t, index + 1
    elseif ot == TYPE.FUNCTION then
        local dump
        dump, index = ('s2'):unpack(stream, index)
        local f, err = load(dump, dump, 'b')
        if not f then
            error(err)
        end
        return f, index
    else
        error('未知的类型：' .. tostring(ot))
    end
end

local function encode(o)
    local buf = {}
    encodeValue(buf, o)
    return table.concat(buf)
end

local function decode(stream)
    return decodeValue(stream, 1)
end

return {
    encode = encode,
    decode = decode,
}
