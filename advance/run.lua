require 'efw_support'
local lfsp = require 'lfsp'

local exec_ext = ''
local delim = '():'
if(package.config:sub(1,1) == '\\') then
    exec_ext = '.exe'
    delim = '();'
end

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

-- 参数定义
local config = {
    cc = {
        dir = '$MINGW_HOME/bin',
        dir = '',
        exec = 'gcc',
        params = {
            { EN = true, val = ' -o "%s"'},
            { EN = true, val = ' "%s"'},
            { EN = false, val = ' -lws2_32'}
        }
    },
    cxx = {
        dir = '$MINGW_HOME/bin',
        dir = '',
        exec = 'g++',
        params = {
            { EN = true, val = ' -o "%s"'},
            { EN = true, val = ' "%s"'},
            { EN = false, val = ' -lws2_32'}
        }
    },
    cmake = {
        dir = '$CMAKE_HOME/bin',
        dir = '',
        exec = 'cmake',
        params = {
            { EN = true, val = ' "%s"'},
            { EN = true, val = ' -G "MinGW Makefiles"'}
        }
    },
    javac = {
        dir = '$JAVA_HOME/bin',
        dir = '',
        exec = 'javac',
        params = {
            { EN = true, val = ' "%s"'},
            { EN = true, val = ' -encoding utf8'}
        }
    },
    java = {
        dir = '$JAVA_HOME/bin',
        dir = '',
        exec = 'java',
        params = {
            { EN = true, val = ' "%s"'}
        }
    },
    lua = {
        dir = '$LUA_HOME/bin',
        dir = '',
        exec = 'lua',
        params = {
            { EN = true, val = ' "%s"'}
        }
    },
    python = {
        dir = '$PYTHON_HOME',
        dir = '',
        exec = 'python',
        params = {
            { EN = true, val = ' "%s"'}
        }
    }
}

local RUNNERCLS = { valid = false }

function RUNNERCLS:run(...)
    os.execute(self.exec .. cmd_params(self.params,...))
end

local function newrunner(name)
    init_path()
    local runner = {}
    local status,exec = check_env(config[name].exec,config[name].dir)
    if(status) then 
        setmetatable(runner,{__index = RUNNERCLS})
        runner.valid = true
        runner.exec = exec
        runner.params = config[name].params
    end
    return runner
end

-- 模块入口

local args = {...}
if(#args < 1) then
    print('本模块不支持没有参数运行')
    return 
end

local file = lfsp.new(args[1])
local currentdir = file:get_directory():get_path()
local filename = file:get_file_name()
local namewithoutext = file:get_file_name(true)
local ext = string.lower(file:get_file_ext(true))

lfsp.cd(currentdir)

if(ext == 'c') then
    local cc = newrunner('cc')
    if(cc.valid) then
        cc:run(namewithoutext,filename)
        os.execute(namewithoutext)
    end
elseif(ext == 'cc' or ext == 'cpp') then
    local cxx = newrunner('cxx')
    if(cxx.valid) then
        cxx:run(namewithoutext,filename)
        os.execute(namewithoutext)
    end
elseif(ext == 'java') then
    local javac = newrunner('javac')
    if(javac.valid) then
        javac:run(filename)
    end
    local java = newrunner('java')
    if(java.valid) then
        java:run(namewithoutext)
    end
elseif(ext == 'lua') then
    local lua = newrunner('lua')
    if(lua.valid) then
        lua:run(filename)
    end
elseif(ext == 'py') then
    local python = newrunner('python')
    if(python.valid) then
        python:run(filename)
    end
elseif(ext == 'txt' and string.lower(namewithoutext) == 'cmakelists') then
    local cmake = newrunner('cmake')
    if(cmake.valid) then
        lfsp.mkdir('build')
        local builddir = lfsp.new('build')
        if(builddir:is_directory()) then
            lfsp.cd('build')
            cmake:run('..')
        end
    end
else
    print('暂不支持' .. ext ..'格式')
end