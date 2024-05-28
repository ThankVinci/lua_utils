require 'efw_support'
local lfs = require 'lfs'

local _API = { _VERSION = '1.0' }

local function is_abspath(path)
    if(path:match('()/') == 1) then return true end
    if(path:match('()%a:/') == 1) then return true end
end

local function path_parse(path)
    -- 对输入的路径进行解析，将其变成最简的路径，即去除'.'，'..'
    if(path:sub(#path) ~= '/') then path = path .. '/' end
    local parts = {}
    local last_idx = 1
    for idx in path:gmatch("()/") do
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

local function fix_path(path)
    if(is_abspath(path)) then
        if(path:sub(#path) == '/') then 
            path = path:sub(1,#path-1)
        end
    else
        path = _API.pwd() .. '/' .. path
    end
    return path_parse(path)
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
    local parent_dir = self.path:match('.*/')
    return _API.new(parent_dir)
end

function FILECLS:get_file_name(without_ext)
    local idx = self.path:match('.*()/')
    local file_name = self.path:sub(idx+1)
    if(without_ext) then 
        local tmp = file_name:match('.*%.')
        if(tmp ~= nil) then
            tmp = tmp:sub(1,#tmp-1)
            file_name = tmp
        end
    end
    return file_name
end

function FILECLS:get_file_ext(without_dot)
    local file_name = self:get_file_name()
    local idx = file_name:match('.*()%.')
    local ext = ''
    if(idx ~= nil) then
        if(without_dot) then
            ext = file_name:sub(idx+1)
        else
            ext = file_name:sub(idx)
        end
    end
    return ext
end

function FILECLS:list_files()
    local list = {}
    if(self:is_directory()) then
        for file_name in lfs.dir(self:get_path()) do
            if(file_name == '.' or file_name == '..') then
                goto continue
            end
            local file = _API.new(self:get_path() .. '/' .. file_name)
            table.insert(list,file)
            ::continue::
        end
    end
    return list
end

_API.new = function(path)
    local file = {}
    setmetatable(file,{__index = FILECLS})
    file.path = fix_path(path)
    return file
end

_API.mkdir = function(directory)
    local dir = _API.new(directory)
    if(not dir:path_exists()) then
        _API.mkdir(dir:get_directory():get_path())
        lfs.mkdir(dir:get_path())
    else
        if(dir:is_directory()) then
            --print('"' .. directory .. '"' .. ' 已存在！')
        else
            print('"' .. directory .. '"' .. ' 无法创建！')
        end
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

return _API