--[[
使用须知：
1. 本模块对外提供了四个接口，分别是read_from_string、read_from_file、write_to_string、write_to_file
2. 本模块在实现上会依赖cjson和lfsp
--]]

local cjson = require 'cjson'
local lfsp = require 'lfsp'

local _API = { _VERSION = '1.0' }

local json_codec = cjson.new()

local function read_from_string(str)
    local success,result = pcall(json_codec.decode,str)
    if(not success) then return false,'json 格式无效！' end
    return true,result
end

local function read_from_file(path)
    local file = lfsp.new(path)
    if(not file:is_file()) then
        return false, '"' .. file:get_path() .. '" 不存在' 
    end
    local json_file = io.open(file:get_path(),'r')
    local json_str = json_file:read('*a')
    json_file:close()
    return read_from_string(json_str)
end

local function write_to_string(tbl)
    if(type(tbl) == 'table') then
        return true,json_codec.encode(tbl)
    end
    return false,'入参非table'
end

local function write_to_file(tbl,path)
    local result,str = write_to_string(tbl)
    if(result == true) then 
        local file = lfsp.new(path)
        local directory = file:get_directory()
        lfsp.mkdir(directory:get_path())
        if(directory:is_directory()) then
            local json_file = io.open(file:get_path(),'w')
            json_file:write(str)
            json_file:close()
            return true
        else
            return false,'"' .. file:get_path() .. '" 文件无法写入！'
        end
    end
    return false,str
end

_API.read_from_string = read_from_string
_API.read_from_file = read_from_file
_API.write_to_string = write_to_string
_API.write_to_file = write_to_file

return _API