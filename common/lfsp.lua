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

local function is_abspath(path)
    if(path:match('()/') == 1) then return true end
    if(path:match('()%a:') == 1) then return true end
end

local function is_relpath(path)
    return not is_abspath(path)
end

local function is_rootpath(path)
    if(path:match('()/$') == 1) then return true end
    if(path:match('()%a:/$') == 1) then return true end
end

local function fix_path(path)
    if(is_abspath(path)) then
        return path
    else
        local currentdir = _API.pwd()
        --想办法获取到完整路径（目录树）
        return currentdir .. '/' .. path
    end
end

_API.new = function(path)
    local file = {}
    setmetatable(file,{__index = FILECLS})
    file.path = fix_path(path)
    return file
end

return _API