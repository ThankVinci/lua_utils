--[[
使用须知：
1.本脚本为run.sh的升级版本，因为在Windows上运行run.sh还需要再配置一个bash.exe很麻烦，并且我也试过了在mingw的某个版本上，在bash.exe中执行有std::cout的程序会发生莫名其妙的段错误，所以就直接放弃在Windows上用bash了；
2.本脚本在设计上为单文件运行脚本，支持编译单个c、cpp、java文件并执行，支持运行lua、python脚本、支持执行cmakelists.txt文件（后续会补充一些其他类型的文件）；
3.脚本默认会认为在用户的系统中已经配好了环境变量，可以直接执行命令行，如果查不到运行环境，可以手动配置路径
4.本脚本的使用方法：lua.exe $path/run.lua $filepath
要运行的文件路径是作为本脚本的第一个参数，本脚本会解析路径的文件名和后缀，根据后缀判断文件类型，然后根据在本脚本中的命令行参数配置进行参数拼接；
--]]

-- 配置给notepad++的运行命令，%LUA_HOME%/share/lua/5.4/run.lua是本脚本所在的目录，可以自行更改
-- cmd /k lua.exe %LUA_HOME%/share/lua/5.4/run.lua "$(FULL_CURRENT_PATH)" & PAUSE & EXIT
-- cmd /k lua.exe "C:/Users/ThankVinci/Desktop/Projects/lua_utils/advance/run.lua" "$(FULL_CURRENT_PATH)" & PAUSE & EXIT 

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

-- 参数表 --
local c_params = {
	{EN = true,val = ' -o "%s"'},
	{EN = true,val = ' "%s"'},
	{EN = false,val = ' -lws2_32'}
}

local cxx_params = {
	{EN = true,val = ' -o "%s"'},
	{EN = true,val = ' "%s"'},
	{EN = false,val = ' -lws2_32'}
}

local nasm_params = {
	{EN = true,val = ' "%s"'},
	{EN = true,val = ' -l "%s.lst"'},
	{EN = true,val = ' -o "%s.bin"'}
}

local cmake_params = {
	{EN = true,val = ' "%s"'},
	{EN = true,val = ' -G "MinGW Makefiles"'}
}


local javac_params = {
	{EN = true,val = ' "%s"'},
	{EN = true,val = ' -encoding utf8'}
}

local java_params = {
	{EN = true,val = ' "%s"'}
}

local lua_params = {
	{EN = true,val = ' "%s"'}
}

local py_params = {
	{EN = true,val = ' "%s"'}
}
------------
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

init_path() -- 初始化path
local status,java = check_env('kksk','') -- 初始化path

-- 程序入口

local args = {...}

if(#args < 1) then
    print('本脚本不支持没有参数运行')
    return 
end

local file = lfsp.new(args[1])
local currentdir = file:get_directory():get_path()
local filename = file:get_file_name()
local namewithoutext = file:get_file_name(true)
local ext = string.lower(file:get_file_ext(true))

lfsp.cd(currentdir)

if(ext == 'c') then
    local status,cc = check_env(cc,C_PATH)
    if(status) then
        os.execute(cc .. cmd_params(c_params,namewithoutext,filename))
        os.execute(namewithoutext)
    end
elseif(ext == 'cc' or ext == 'cpp') then
    local status,cxx = check_env(cxx,C_PATH)
    if(status) then
        os.execute(cxx .. cmd_params(cxx_params,namewithoutext,filename))
        os.execute(namewithoutext)
    end
elseif(ext == 'java') then
    local status1,javac = check_env(javac,JAVA_PATH)
    local status2,java = check_env(java,JAVA_PATH)
    if(status1 and status2) then
        os.execute(javac .. cmd_params(javac_params,filename))
        os.execute(java .. cmd_params(java_params,namewithoutext))
    end
elseif(ext == 'lua') then
    local status,lua = check_env(lua,LUA_PATH)
    if(status) then
        os.execute(lua .. cmd_params(lua_params,filename))
    end
elseif(ext == 'py') then
    local status,python = check_env(python,PYTHON_PATH)
    if(status) then
        os.execute(python .. cmd_params(py_params,filename))
    end
elseif(ext == 'txt' and string.lower(namewithoutext) == 'cmakelists') then
    local status,cmake = check_env(cmake,CMAKE_PATH)
    if(status) then
        lfsp.mkdir('build')
        local builddir = lfsp.new('build')
        if(builddir:is_directory()) then
            lfsp.cd('build')
            os.execute(cmake .. cmd_params(cmake_params,'..'))
        end
    end
else
    print('暂不支持' .. ext ..'格式')
end

print(currentdir,filename,namewithoutext,fileext)