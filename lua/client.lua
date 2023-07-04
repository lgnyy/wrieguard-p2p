
local socket = require("socket.core")


local function start(device, address, port, mode, peerIP)
	local cmd_pre = string.format("wg set %s peer ", device)

	local m = socket.udp()
	m:settimeout(10) --b,t
	
	local setx = function(cmd)
		print(string.format("[%d][client] sendto(%s:%d), data:", os.millisecond(), address, port), cmd)
		assert(m:sendto(cmd, address, port))
		
		for i=1,2 do
			local data,remoteAddress,remotePort = assert(m:receivefrom())
			print(string.format("[%d][client] receivefrom(%s:%d), data:", os.millisecond(), remoteAddress, remotePort), data)
			if (i == 1) then
				local _,cmd_data = data:match("^([^ ]+) (.+)$")
				os.execute(cmd_pre .. cmd_data)
			end
		end
	end
	
	setx(mode .. " " .. peerIP)
	
	if (mode:match("^setx")) then
		--参考 https://github.com/luaposix/luaposix
		require("sysapi").set_ctrl_handler(function(ct)
			setx("remove " .. peerIP)
			os.exit(0)
		end)
		
		local cmd2 = "ping " .. peerIP
		while(1) do
			print("PLS press CTRL+C to exit...");
			os.sleep(10)
			print(string.format("[%d][client] sendto(%s:%d), data:", os.millisecond(), address, port), cmd2)
			assert(m:sendto(cmd2, address, port))
			local data,remoteAddress,remotePort = m:receivefrom()
			if (not data) then
				print(string.format("[%d][client] err", os.millisecond()), remoteAddress)
			else
				print(string.format("[%d][client] receivefrom(%s:%d), data:", os.millisecond(), remoteAddress, remotePort), data)
			end
		end
	else
		os.sleep(5)
	end


	m:close()
	
	print(string.format("[%d][client] close", os.millisecond()))
end

start(arg[1] or "wg0", arg[2] or "10.0.8.1", arg[3] or 33055, arg[4] or "setx", arg[5] or "10.0.8.27")
