STAT_DUG = 1
STAT_PLACED = 2
STAT_DIED = 3
STAT_TRAVEL = 4
STAT_PK = 5
STAT_KILLS = 6

if default.deserialize_from_file ~= nil then
	deserialize_from_file = default.deserialize_from_file
else
	deserialize_from_file = function(filename)
		local f = io.open(filename, "r")
		if f==nil then 
			return {}
		end
			local t = f:read("*all")
			f:close()
		if t=="" or t==nil then 
			return {}
		end
		return minetest.deserialize(t)
	end
end

if default.serialize_to_file ~= nil then
	serialize_to_file = default.serialize_to_file
else
	serialize_to_file = function (filename,t)
		local f = io.open(filename, "w")
		if f ~= nil then
			f:write(minetest.serialize(t))
			f:close()
		else
			minetest.log("error","Unable to open for writing "..tostring(filename))
		end
	end
end


local player_data = {}
local player_dir = minetest.get_worldpath() .. "/"

pd = {}

pd.is_online = function(name)
	if player_data[name] ~= nil then
		return true
	else	
		return false
	end
end

pd.load_player = function(name)	
	if player_data[name] == nil then	-- prevent loading the player twice... specifically when a new player joins 
		player_data[name] = deserialize_from_file(player_dir..name..".data")
	end	
end

pd.unload_player = function(name)
	pd.save_player(name)
	player_data[name] = nil
end

pd.save_player = function(name)
	if player_data[name] ~= nil then
		serialize_to_file(player_dir..name..".data",player_data[name])
	end
end

pd.save_all = function(again)
	minetest.log("action","Saving player data...")
	for name,_ in pairs(player_data) do
		if player_data[name] ~= nil then
			pd.save_player(name)
		end
	end
	if again == true then
		minetest.after(300,pd.save_all,true)
	end
end

pd.get = function(name,param)
	if pd.validate(name,param) then
		return player_data[name][param]
	else
		return nil
	end
end

pd.get_number = function(name,param)
	return tonumber(pd.get(name,param)) or 0
end

pd.set = function(name, param, value)
	if pd.validate(name,param) then
		player_data[name][param] = value
	else
		minetest.log("error","Unable to set "..tostring(param).." to "..tostring(value)) 
	end
end

pd.unset = function(name, param)
	pd.set(name,param,nil)
end

pd.increment = function (name, param, amount)
	local oval = pd.get_number(name,param)
	local val = oval + amount
	pd.set(name,param,val)
end

pd.validate = function (name,param)
	if name ~= nil and param ~= nil then
		if player_data[name] ~= nil then
			return true
		else
			minetest.log("action",param.." did not validate for "..name)
			return false
		end
	else
		minetest.log("action",param.." did not validate for "..name)
		return false
	end
end

pd.dump = function()
	default.tprint(player_data,4)
end

minetest.after(300,pd.save_all,true)
