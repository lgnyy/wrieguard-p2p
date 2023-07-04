
local socket = require("socket.core")


-- pingXXX-ip-port reqIP -> pingXXX-ip-port pong
-- setxXXX-ip-port publicKey... -> setxXXX-ip-port success
local function start(device, address, port)
	print(string.format("[%d][wgsvr] open(address=%s, port=%d, device=%s)", os.millisecond(), address, port, device))
	
	local cmd_pre = string.format("wg set %s peer ", device)
	local workInfos = {}
	local m = socket.udp()
	m:settimeout(5) --b,t
	assert(m:setsockname(address, port))
		
	local removeWork = function (wis, publicKey)
		for k,v in pairs(wis) do
			if (v.publicKey == publicKey) then
				wis[k] = nil
				break
			end
		end
	end

	local timeoutWork = function (wis, cb)
		for k,v in pairs(wis) do
			v.tickCount = v.tickCount + 1
			if (v.tickCount == 6) then
				wis[k] = nil
				cb(v)
				break
			end
		end
	end

		
	while(true) do
		local cmd_id,cmd_data
		local data,remoteAddress,remotePort = m:receivefrom()
		if (not data) then
			--print(string.format("[%d][wgsvr] err", os.millisecond()), remoteAddress)			
			timeoutWork(workInfos, function(v)
				print(string.format("[%d][wgsvr] remove(%s)", os.millisecond(), v.publicKey))
				os.execute(cmd_pre .. v.publicKey .. " remove")
			end)
		else
			print(string.format("[%d][wgsvr] receivefrom(%s:%d), data:", os.millisecond(), remoteAddress, remotePort), data)
			cmd_id,cmd_data = data:match("^([^ ]+) (.+)$")
		end
		
		if (cmd_id and cmd_data) then		
			if cmd_id:find("^ping") then
				local workInfo = workInfos[cmd_data]
				if (workInfo) then
					workInfo.tickCount = 0
				end
				m:sendto(cmd_id .. " pong", remoteAddress, remotePort)
			else
				-- 执行新配置
				local ok = os.execute(cmd_pre .. cmd_data)
				assert(m:sendto(cmd_id .. (ok and " success" or " fail"), remoteAddress, remotePort))
				
				if ok then
					local publicKey = cmd_data:sub(1, 1+44)
					removeWork(workInfos, publicKey)

					-- 需要心跳维护
					if (not cmd_data:find("remove$")) and (not cmd_id:find("^set0")) then
						local peerIP = cmd_data:match("allowed%-ips ([^/]+)")
						if peerIP then
							workInfos[peerIP] = {publicKey=publicKey, tickCount=0}
						end
					end
				end
			end
		end
	end

	m:close()

	print(string.format("[%d][wgsvr] close", os.millisecond()))
end

local function daemon(arg1, arg2, arg3)
	while(true) do
		print(string.format("[%d][wgsvr] daemon", os.millisecond()))
		local ok,err = pcall(start, arg1, arg2, arg3)
		if (not ok) then
			print(string.format("[%d][wgsvr] err", os.millisecond))
		end
		os.sleep(15)
	end
end


--arg[1] = "daemon"
if (arg[1] == "daemon") then
	daemon(arg[2], arg[3], arg[4])
else
	start(arg[1] or "wg0", arg[2] or "0.0.0.0", arg[3] or 33055)
end
