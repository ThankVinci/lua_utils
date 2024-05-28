require 'efw_support'
local lfs = require 'lfs'

local _API = { _VERSION = '1.0' }

_API.mkdir = function(directory)
    local dir = _API.new(directory)
    if(not dir:path_exists()) then
        lfs.mkdir(dir:get_path())
    else
        print('"' .. directory .. '"' .. ' 无法创建')
    end
end

_API.pwd = function()
    local path = lfs.currentdir()
    path = path:gsub('\\','/')
    return path
end

_API.cd = function(directory)
    local dir = _API.new(directory)
    if(dir:is_directory()) then
        lfs.chdir(dir:get_path())
    else
        print('"' .. directory .. '"' .. ' 不是一个目录')
    end
end

local function is_abspath(path)
    if(path:match('()/') == 1) then return true end
    if(path:match('()%a:/') == 1) then return true end
end

local function is_relpath(path)
    return not is_abspath(path)
end

local function is_rootpath(path)
    if(path:match('()/$') == 1) then return true end
    if(path:match('()%a:/$') == 1) then return true end
end

local function path_parse(path)
    -- 对输入的路径进行解析，将其变成最简的路径，即去除'.'，'..'
    if(path[#path] ~= '/') then path = path .. '/' end
    local parts = {}
    local last_idx = 1
    for idx in string.gmatch(path, "()/") do
        local part = path:sub(last_idx,idx-1)
        if(part == '.' or part == '') then goto continue end
        if(part == '..') then
            table.remove(parts)
            goto continue
        end
        table.insert(parts,part)
        ::continue::
        last_idx = idx + 1
    end
    path = parts[1]
    for i,v in ipairs(parts) do
        if(i == 1) then goto continue end
        path = path .. '/' .. parts[i]
        ::continue::
    end
    if(#parts == 1) then path = path .. '/' end
    if(#parts == 0) then path = '' end
    return path
end
local path = "C:/1/2/3/4/./../123/../../../../..//."
path = path_parse(path)
print(path)

local function fix_path(path)
    if(is_abspath(path)) then
        return path
    else
        local currentdir = _API.pwd()
        --想办法获取到完整路径（目录树）
        return currentdir .. '/' .. path
    end
end

local FILECLS = { path = '' }

function FILECLS:path_exists()
    local attributes = lfs.attributes(self.path)
    if(attributes == nil) then return false end
    return true
end

function FILECLS:is_file()
    local attributes = lfs.attributes(self.path)
    if(attributes ~= nil and attributes.mode == 'file')
    then return true end
    return false
end

function FILECLS:is_directory()
    local attributes = lfs.attributes(self.path)
    if(attributes ~= nil and attributes.mode == 'directory')
    then return true end
    return false
end

function FILECLS:get_path()
    return self.path
end

function FILECLS:get_directory()
    
end

function FILECLS:get_file_name()
    
end

function FILECLS:get_file_ext()
    
end

function FILECLS:list_files()
    
end

_API.new = function(path)
    local file = {}
    setmetatable(file,{__index = FILECLS})
    file.path = fix_path(path)
    return file
end

return _API