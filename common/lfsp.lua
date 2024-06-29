--[[
使用须知：
1. 本模块对外提供了四个接口；cd、pwd、mkdir与new，其中规范化文件路径的分隔符，使用'/'作为路径分隔符
2. 本模块实现了一个文件类型，可通过模块的new接口创建出文件对象，文件对象的路径会被修正为完整的绝对路径
3. cd、pwd、mkdir以及文件对象能够判断路径是否存在、是否是目录/文件和列出子文件的功能，均是在lfs库原有的基础之上进行的封装
4. 文件对象创建暂时没有对路径字符串进行校验、无法防止一些不该存在的字符出现在路径中，但一般的使用已经足够了
5. 在Windows系统下为了能够正常支持UTF8字符，应该加载efw，此处直接使用efw_support不区分平台，其他平台不会导入efw
--]]
require 'efw_support'
local lfs = require 'lfs'

local _API = { _VERSION = '1.0' }

local function is_abspath(path)
    if(path:match('()/') == 1) then return true end
    if(path:match('()%a:/') == 1) then return true end
    return false
end

local function is_rootpath(path)
    if(path:match('()/$') == 1) then return true end
    if(path:match('()%a:/$') == 1) then return true end
    return false
end

local function path_parse(path)
    -- 对输入的路径进行解析，将其变成最简的路径，即去除'.'，'..'
    if(path:sub(#path) ~= '/') then path = path .. '/' end
    local parts = {}
    local last_idx = 1
    for idx in path:gmatch("()/") do
        local part = path:sub(last_idx,idx-1)
        if(part == '.' or ( part == '' and idx > 1 )) then goto continue end
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
    path = path:gsub('\\','/')
    if(is_abspath(path)) then
        if(path:sub(#path) == '/' and not is_rootpath(path)) then 
            path = path:sub(1,#path-1)
        end
    else
        path = _API.pwd() .. '/' .. path
    end
    if(not is_rootpath(path)) then 
        path = path_parse(path)
    end
    return path
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

function FILECLS:get_root()
    local root_dir = self.path:match('%a:/')
    if(root_dir == nil) then root_dir = '/' end
    return _API.new(root_dir)
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
        if(is_rootpath(dir:get_path())) then
            return false
        end
        if(_API.mkdir(dir:get_directory():get_path()) == false) then
            return false
        else
            lfs.mkdir(dir:get_path())
            return true
        end
    else
        if(dir:is_directory()) then
            --print('"' .. directory .. '"' .. ' 已存在！')
            return true
        else
            print('"' .. directory .. '"' .. ' 无法创建！')
            return false
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