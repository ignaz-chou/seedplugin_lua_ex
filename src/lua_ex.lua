--[[
Seed基础插件：lua_ex

	版本：
		v1.5

	最后修改日期：
		2013-4-10
	
	更新记录：
		2013-4-10 v1.5:
			添加了addOnceListener方法
		2013-1-28:
			去除了可能引发问题的__FILE__ __LINE__ __FUNCTION__三个函数。
		2012-12-12：
			修改了bind函数
			增加了弱key and value引用表
			增加了warning，assert函数
			增加utf-8向unicode的转换函数
]]

require("globalAlert").disableInThisModule()
_G._LUA_EX_VER = 10003
function nop()
end

function values(...)
    return ...
end

function toboolean(v)
	return (v and true) or false
end

function is_function(v)
	return 
		type(v) == 'function' or
			((type(v) == 'table' or type(v) == 'userdata') and
				getmetatable(v) and is_function(getmetatable(v).__call))
end

local wkt = {__mode = "k"}
local wvt = {__mode = "v"}
local wwt = {__mode = "kv"}
function newWeakKeyTable()
	local ret = {}
	setmetatable(ret, wkt)
	return ret
end

function newWeakValueTable()
	local ret = {}
	setmetatable(ret, wvt)
	return ret
end

function newWholeWeakTable()
	local ret = {}
	setmetatable(ret, wwt)
	return ret
end
local unpack = table.unpack
function bind(f, ...)
    local args = {...}
    return function ()
        return f(unpack(args))
    end
end

function true_()
    return true
end

function false_()
    return false;
end

----------------------------------------------------------------
--- string库扩展
----------------------------------------------------------------

function string:topattern()
    local ret = self:gsub("%p", "%%%1")
    return ret
end

function string:replace(str, repl)
    local ret= self:gsub(str:topattern(), repl:topattern())
	return ret
end

function string:split(pattern, plain, trimEmpty)
    if (plain) then
        pattern = pattern:topattern()
    end
    local t={}
    local p=1
    for pos,to in string.gmatch(self, "()"..pattern.."()") do
        if ((not trimEmpty) or (p ~= pos)) then
            table.insert(t, self:sub(p,pos - 1))
        end
        p = to
    end
    if ((not trimEmpty) or (p<=#self)) then
        table.insert(t, self:sub(p))
    end
    return t
end
--检测字符串是否以某特定字符串开头
function string:startsWith(t)
	return self:sub(1, #t) == t
end
--检测字符串是否以某特定字符串结尾
function string:endsWith(t)
	return self:sub(-#t ) == t
end

----------------------------------------------------------------
--- table库扩展
----------------------------------------------------------------
--将table中所有key返回一个table
function table:keys()
    local ret = {}
    for k,v in pairs(self) do
        table.insert(ret, k)
    end
    return ret
end

--根据value寻找,而非key.使用ipairs
function table:find(val)
	for i,v in ipairs(self) do
		if (v == val) then
			return i
		end
	end
end
--根据value寻找,而非key.使用pairs
function table:findVal(val)
	for k,v in pairs(self) do
		if (v == val) then
			return k
		end
	end
end

--移除table中指定value的key
function table:removeVal(val)
	local  pos = table.find(self,val)
	if (pos) then
		table.remove(self, pos)
	end
end

function table:removeIf(test)
	local j = 1
	local l = #self

	for i = 1, l do
		if (not test(self[i])) then
			if (j~=i) then
				self[j] = self[i]
			end
			j = j + 1
		end
	end

	for i = j, l do
		self[i] = nil
	end
end

--复制一个table.
--由于table的等号实际为引用,会影响原始table,故有此函数
function table:clone()
	local ret = {}
	for k,v in pairs(self) do
		ret[k] = v
	end
	return ret
end

function table:findFirst()
	for k, v in pairs(self) do
		if k and v then	
			return k, v
		end
	end
end

--获取table长度
--#table 只能获取编号顺序排布的table的长度
function table:getLength()
	local ret = 0
	for k, v in pairs(self) do
		ret = ret + 1
	end
	return ret
end

function table:reverse()
	local l = #self
	for i = 1, l/2 do
		local j = l-i+1
		self[i], self[j] = self[j], self[i]
	end
	return self
end

table.pop = table.remove
table.push = table.insert

----------------------------------------------------------------
--- math库扩展
----------------------------------------------------------------
--用于获取正负号
function math.sign(n)
	if (n > 0) then
		return 1
	elseif (n < 0) then
		return -1
	else
		return 0
	end
end

function math.clamp(v, min, max)
	if (v < min) then
		return min
	elseif (v > max) then
		return max
	else
		return v
	end
end

----------------------------------------------------------------
--- printTable
----------------------------------------------------------------
local level_ = 1
local function _getSpace(level)
	local ret = ""
	for i = 1, level do
		ret = ret .. "    "
	end
	if level > 1 then
		ret = ret-- .. "|-  "
	end
	return ret
end
---打印table,会循环遍历打印每一层,maxLevel为最大层数,默认为6
---会自动插入空格使table层次分明
---注意:尽量避免在环状table中使用太高层次
function printTable(t, maxLevel)
	maxLevel = maxLevel or 3
	if t == nil then
		print(t)
		return
	end
	for k, v in pairs(t) do
		if type(k) == "number" then k = "[" .. k .. "]" end
		if maxLevel < level_ then
			return 
		end
		print(_getSpace(level_), k, "=" , v)
		if type(v) == "table" then
			level_ = level_ + 1
			printTable(v, maxLevel)
			level_ = level_ - 1
		end
	end
end

function outTable(t, maxLevel)
	maxLevel = maxLevel or 6
	if t == nil then
		print(t)
		return
	end
	local v_str
	for k, v in pairs(t) do
		if type(k) == "number" then k = "[" .. k .. "]" end
		if maxLevel < level_ then
			return 
		end
		if not v then
			v_str = "nil,"
		end
		if type(v) == "string" then
			v_str = '\"' .. v .. '\",'
		elseif type(v) == "table" then
			v_str = "{"
		elseif type(v) == "boolean" then
			v_str = (v and "true") or "false" .. ","
		else
			v_str = v .. ","
		end
		print(_getSpace(level_) .. k, "=" , v_str)
		if type(v) == "table" then
			level_ = level_ + 1
			outTable(v, maxLevel)
			level_ = level_ - 1
			print(_getSpace(level_) .. "},")
		end
	end
end

--是否近似相等，浮点数在经过运算后会产生误差，通常它们之间的比较都使用近似相等
function math.epsEqual(a, b)
	local eps = 0.000001
	local r = a - b
	return -eps < r and r < eps
end

function getGlobal(name, _initTbl)
	local pkg, rn = name:match("(.+)%.(%w*)")
	if (pkg) then
		pkg = getGlobal(pkg, _initTbl)
		if (not pkg) then
			return nil
		end
	else
		pkg = _G
		rn = name
	end
	if (_initTbl and not pkg[rn]) then
		pkg[rn] = {}
	end
	return pkg[rn]
end

function setGlobal(name, val)
	local pkg, rn = name:match("(.+)%.(%w*)")
	if (pkg) then
		pkg = getGlobal(pkg, true)
	else
		pkg = _G
		rn = name
	end
	pkg[rn] = val
end

---警告,手动调用,会显示调用栈.
function warning(msg)
	print('Warning: '..msg..'\n'..debug.traceback())
end


----------------------------------------------------------------
--- event扩展
----------------------------------------------------------------
local Dispatcher = event.Dispatcher.methods
---添加模块事件,当切出模块时,事件自动销毁.input.key等全局事件请尽量使用此方法
function Dispatcher:addModuleListener(func)
	local rtAgent = require("director").currentRuntimeAgent()
	local function remove()
		rtAgent.destroy:removeListener(remove)
		self:removeListener(func)
	end
	rtAgent.destroy:addListener(remove)
	self:addListener(func)
end
---添加只执行一次的事件,执行完毕后自动销毁
local function addOnceListener(ev,func)
	local function runOnce(...)
		func(...)
		ev:removeListener(runOnce)
	end
	ev:addListener(runOnce)
	return runOnce
end
Dispatcher.addOnceListener = addOnceListener

function _G:addEventListener(name, ...)
	local ev = self[name]
	if (ev == nop or not ev) then
		ev = event.Dispatcher.new()
		self[name] = ev
	end
	ev:addListener(...)
end

function _G:removeEventListener(name, ...)
	local ev = rawget(self, name)
	if (ev) then
		ev:removeListener(...)		
	else
		warning("Listener was not added.")
	end
end

function _G:dispatchEvent(name, ...)
	local ev = rawget(self, name)
	if (ev) then
		ev(...)
	end
end

function _G:dispatchEventWithSelf(name, ...)
	local ev = rawget(self, name)
	if (ev) then
		ev(self, ...)
	end
end


function _G.resetRequired(modulename) --重置被require的模块
	local required = doscript(modulename)
	_G.package.loaded[modulename] = required
	return required
end

--复制map,将map中已有项覆盖至to
function copyMap(map, to)
	to = to or {}
	for k,v in pairs(map) do
		to[k] = v
	end
	return to
end

function mergeMap(base, override)
	return copyMap(override, copyMap(base))
end

function io.readFile(uri)
	local f = io.open(uri, "r")
	if (not f) then
		return nil, "Cannot open uri "..uri
	end
	local ret = f:read()
	f:close()
	return ret
end

function io.writeFile(uri, data)
	local f = io.open(uri, "w")
	if (not f) then
		return nil, "Cannot write uri "..uri
	end
	f:write(data)
	f:close()
	return true
end

--[[
read lines from a stream.
sample:
local fd = io.open("res://main.lua", "r")
local i = 0
for line in fd:lines() do -- or lines(fd)
	i = i +1
	print(i..':\t', line)
end
fd:close()
]]
function lines(fd)
	local buf = ""
	local function get_line()
		if (not buf) then
			return buf
		end
		while (true) do
			local line, rest
			line, rest = buf:match("([^%\n]*)%\n(.*)")
			if (line) then
				buf = rest
				return line
			end

			local tmp = fd:read(512)
			if (not tmp) then
				tmp, buf = buf, nil
				return tmp
			end

			buf = buf..tmp
		end
	end
	return get_line, nil, nil
end

io.InputFileStream.methods.lines = lines

function utf8_2_unicode(str)
	local ret = {}

	local i = 1
	local l = #str
	while (i<=l) do
		local ch = str:byte(i) or 0

		if (ch < 0x80) then
		elseif (ch < 0xC0) then
			ch = 63  -- '?' char
		elseif (ch < 0xE0) then
			local ch1 = str:byte(i) or 0
			i = i+1
			ch = bit32.lshift(bit32.band(ch, 0x1F), 6) + bit32.band(ch1, 0x3F)
		elseif (ch < 0xF0) then
			local ch1 = str:byte(i+1) or 0
			local ch2 = str:byte(i+2) or 0
			i = i+2
			ch = bit32.lshift(bit32.band(ch, 0x1F), 12) 
				+ bit32.lshift(bit32.band(ch1, 0x3F), 6) 
				+ bit32.band(ch2, 0x3F)
		end
		
		table.insert(ret, ch)

		i = i+1
	end

	return ret
end

function clamp(v, min, max)
	if (v < min) then
		return min
	elseif (v > max) then
		return max
	else
		return v
	end
end

function parseColor(s)
	local ret = {}
	for p in s:gmatch("(%x%x)") do
		table.insert(ret, tonumber(p, 16) / 255)
	end
	if (#ret == 3) then
		return 1, table.unpack(ret)
	elseif (#ret == 4) then
		return table.unpack(ret)
	else
		error(s .. " is not a color string.")
	end
end