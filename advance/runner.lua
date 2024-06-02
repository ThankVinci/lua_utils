--[[
使用须知：
1.本模块与runner.json配置文件是搭配使用的，runner.json中记录了一些可执行文件的配置，包括gcc、g++、javac等，本模块的本质上是调用命令行，将执行命令行的参数进行封装，通过new函数返回一个运行器对象，上层就无需考虑这些可执行文件是否存在了；
--]]
require 'efw_support'
local lfsp = require 'lfsp'
local json_io = require 'json_io'

local exec_ext = ''
local delim = '():'
if(package.config:sub(1,1) == '\\') then
    exec_ext = '.exe'
    delim = '();'
end

local _API = { _VERSION = '1.0' }

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

-- 检查环境
local function check_env(exec,path)
    if(path == '') then
        if(type(_PATH) == 'table') then
            for i,v in ipairs(_PATH) do
                local tmp_file = lfsp.new(v .. '/' .. exec .. exec_ext)
                if(tmp_file:is_file()) then
                    return true,exec
                end
            end
        end
    else
        local tmp_file = lfsp.new(path .. '/' .. exec .. exec_ext)
        if(tmp_file:is_file()) then
            exec = tmp_file:get_path()
            return true,exec
        end
    end
    return false,exec
end

-- 组装参数
local function cmd_params(tp,...)
    local cmd = ''
    local args = {...}
    for i=1,#tp do
        if(tp[i].EN) then
            if(args[i]) then
                cmd = cmd .. tp[i].val:format(args[i])
            else
                cmd = cmd .. tp[i].val
            end
        end
    end
    return cmd
end

local RUNNERCLS = { valid = false }

function RUNNERCLS:run(...)
    os.execute(self.exec .. cmd_params(self.params,...))
end

_API.new = function(name)
    init_path()
    local runner = {}
    local exec
    local status,config = json_io.read_from_file('runner.json')
    if(status) then 
        status,exec = check_env(config[name].exec,config[name].dir)
    end
    print(status)
    if(status) then 
        setmetatable(runner,{__index = RUNNERCLS})
        runner.valid = true
        runner.exec = exec
        runner.params = config[name].params
    end
    return runner
end

return _API