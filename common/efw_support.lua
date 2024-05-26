--[[
使用须知：
1.本模块进行系统判断如果目录分隔符为'\'就认定为Windows系统，然后就会加载efw模块，efw模块是在Windows上对lua原生API进行utf8支持的模块，也就是说在引入时就替换掉原生带的一些对Windows上utf8支持不好的函数（目前模块正在扩充中）
2.在这一过程中用户是无感知的，也就是说当require 'efw'之后，用户无需更改脚本，比方说：
	os.execute('echo 哈哈') 这条语句如果是utf8编码，那么它在Linux下执行是没问题的，但是在Windows下就会输出乱码，而在执行这条语句前，如果require 'efw'，就会把os.execute函数直接替换成支持utf8的版本，因此输出就是正常的中文
--]]

if(package.config:sub(1,1) == '\\') then
	require 'efw'
end