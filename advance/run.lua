--[[
使用须知：
1.本模块为run.sh的升级版本，因为在Windows上运行run.sh还需要再配置一个bash.exe很麻烦，并且我也试过了在mingw的某个版本上，在bash.exe中执行有std::cout的程序会发生莫名其妙的段错误，所以就直接放弃在Windows上用bash了；
2.本模块在设计上为单文件运行模块，支持编译单个c、cpp、java文件并执行，支持运行lua、python脚本、支持执行cmakelists.txt文件（后续会补充一些其他类型的文件）；
3.本模块的使用方法：lua.exe $path/run.lua $filepath
要运行的文件路径是作为本模块的第一个参数，本模块会解析路径的文件名和后缀，根据后缀判断文件类型，然后根据在本模块中的命令行参数配置进行参数拼接；
--]]
-- 配置给notepad++的运行命令，%LUA_HOME%/share/lua/5.4/run.lua是本模块所在的目录，可以自行更改
-- cmd /k lua.exe %LUA_HOME%/share/lua/5.4/run.lua "$(FULL_CURRENT_PATH)" & PAUSE & EXIT
-- cmd /k lua.exe "C:/Users/ThankVinci/Desktop/Projects/lua_utils/advance/run.lua" "$(FULL_CURRENT_PATH)" & PAUSE & EXIT 

require 'efw_support'
local lfsp = require 'lfsp'
local runner = require 'runner'

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
    local cc = runner.new('cc')
    if(cc.valid) then
        cc:run(namewithoutext,filename)
        os.execute(namewithoutext)
    end
elseif(ext == 'cc' or ext == 'cpp') then
    local cxx = runner.new('cxx')
    if(cxx.valid) then
        cxx:run(namewithoutext,filename)
        os.execute(namewithoutext)
    end
elseif(ext == 'java') then
    local javac = runner.new('javac')
    if(javac.valid) then
        javac:run(filename)
    end
    local java = runner.new('java')
    if(java.valid) then
        java:run(namewithoutext)
    end
elseif(ext == 'lua') then
    local lua = runner.new('lua')
    if(lua.valid) then
        lua:run(filename)
    end
elseif(ext == 'py') then
    local python = runner.new('python')
    if(python.valid) then
        python:run(filename)
    end
elseif(ext == 'txt' and string.lower(namewithoutext) == 'cmakelists') then
    local cmake = runner.new('cmake')
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

print(currentdir,filename,namewithoutext,fileext)