require 'efw_support'
local lfs = require 'lfs'

local _API = {}
_API._VERSION = '1.0'

local FILECLS = { path = '',valid = false }

function FILECLS:path_exists()
    local attributes = lfs.attributes(self.path)
    if(attributes == nil) then return false end
    return true
end

function FILECLS:get_path()
    return self.path
end

function FILECLS:is_valid()
    return self.valid
end

function FILECLS:is_file()
    if(not self:path_exists(self.path)) then return false end
    local attributes = lfs.attributes(self.path)
    if(attributes.mode == 'file') then return true end
    return false
end

function FILECLS:is_directory()
    if(not self:path_exists(self.path)) then return false end
    local attributes = lfs.attributes(self.path)
    if(attributes.mode == 'directory') then return true end
    return false
end

function FILECLS:get_directory()
    
end

function FILECLS:get_file_name()
    
end

function FILECLS:get_file_ext()
    
end

_API.new = function(path)
    local file = {}
    setmetatable(file,{__index = FILECLS})
    file.path = path
    if(file:path_exists()) then
        return file
    end
    return nil
end

return _API