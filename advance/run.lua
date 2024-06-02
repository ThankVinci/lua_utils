package.path = '../common/?.lua;' .. package.path
require 'efw_support'
local lfsp = require 'lfsp'

local exec_ext = ''
local delim = '():'
if(package.config:sub(1,1) == '\\') then
    exec_ext = '.exe'
    delim = '();'
end

--获取用于运行的环境变量--
local C_PATH = '' --os.getenv('MINGW_HOME') .. '/bin/'
local CMAKE_PATH = '' --os.getenv('CMAKE_HOME') .. '/bin/'
local JAVA_PATH = '' --os.getenv('JAVA_HOME') .. '/bin/'
local LUA_PATH = '' --os.getenv('LUA_HOME') .. '/bin/'
local PYTHON_PATH = '' --os.getenv('PYTHON_HOME') .. '/'

local cc = 'gcc'
local cxx = 'g++'
local make = 'make'
local cmake = 'cmake'
local javac = 'javac'
local java = 'java'
local lua = 'lua'
local python = 'python'

-- 初始化一次path，将系统环境变量中的PATH分解成若干个目录
local function init_path()
    if(_PATH == nil) then
        local PATH = os.getenv('PATH')
        _PATH = {}
        local last_idx = 1
        for idx in PATH:gmatch(delim) do
            local path = PATH:sub(last_idx,idx-1)
            table.insert(_PATH,path)
            last_idx = idx + 1
        end
        if(last_idx < #PATH) then -- 若PATH中最后一个路径没有以目录的分隔符结束
            local path = PATH:sub(last_idx,#PATH)
            table.insert(_PATH,path)
        end
    end
end

--检查所需的环境是否存在，只要找到一个Path符合就返回true
local function check_env(exec)
    if(type(_PATH) == 'table') then
        for i,v in ipairs(_PATH) do
            local tmp_file = lfsp.new(v .. '/' .. exec .. exec_ext)
            if(tmp_file:is_file()) then
                return true
            end
        end
    end
    return false
end

init_path() -- 初始化path
check_env(java) -- 初始化path

local args = {...}

if(#args < 1) then
    print('本脚本不支持没有参数运行')
    return 
end