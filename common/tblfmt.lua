--[[
使用须知：
本模块实现了对table数据进行字符串格式化的操作，能够遍历table的每一层进行连接，table的字典部分是没办法按顺序遍历的，数组部分是可以的。
--]]

require 'efw'

local _API = { _VERSION = '0.1' }


--sepkey是table中字典部分中作为分隔符存在的key的名称，table的每一层的字典部分都应该具有一个分隔符，且他们的名称都一样，当然如果没有这个分隔符的话也没关系，默认会以空格对一层的val进行连接，table的数组部分只能以空格进行分隔。
function process(tbl,sepkey)
    if(type(tbl) == 'table') then
        local sep = ' '
        if(type(sepkey) == 'string' and type(tbl[sepkey]) == 'string') then
            sep = tbl[sepkey]
        end
        local str = ''
        local _sep = ''
        for k,v in pairs(tbl) do
            if(k == sepkey) then goto continue end
            if(type(v) == 'string') then 
                if(type(k) == 'string') then
                    str = str .. string.format('%s%s%s',_sep,k,v)
                elseif(type(k) == 'number') then
                    str = str .. string.format('%s%s',_sep,v)
                end
            elseif(type(v) == 'table') then 
                if(type(k) == 'string') then
                    str = str .. string.format('%s%s%s',_sep,k,process(v,sepkey))
                elseif(type(k) == 'number') then
                    str = str .. string.format('%s%s',_sep,process(v,sepkey))
                end
            end
            _sep = sep
            ::continue::
        end
        return str
    end
    return ''
end

_API.process = process

return _API
