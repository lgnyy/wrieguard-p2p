
local socket = require("socket.core")

local function parseConf(conf)
	local result={}, tmp
	string.gsub(conf, "[^\n]+", function(line)
		if (line:find("^peer: ")) then
			if tmp then
				local ip = tmp["allowed ips"]
				result[ip:sub(1, ip:find("/")-1)] = tmp				
			end
			tmp = {["public key"] = line:sub(1+6)}
		elseif (line:find("^  endpoint: ")) then
			tmp["endpoint"] = line:sub(1+12)
		elseif (line:find("^  allowed ips: ")) then
			tmp["allowed ips"] = line:sub(1+15):gsub(" ", "")
		end		
	end)
	if tmp then
		local ip = tmp["allowed ips"]:match("([^/]+)")
		result[ip] = tmp				
	end
	return result
end

-- pingXXX  peerIP -> (pingXXX-ip-port reqIP -> pingXXX-ip-port pong) -> pingXXX pong
-- setxXXX  peerIP -> (setxXXX-ip-port publicKey... -> setxXXX-ip-port success) ->setxXXX success reqIP
local function start(device, address, port)
	print(string.format("[%d][wgtrf] open(address=%s, port=%d, device=%s)", os.millisecond(), address, port, device))
	
	local cmd_show = "wg show " .. device
	local m = socket.udp()
	assert(m:setsockname(address, port))
		
	while(true) do
		local cmd,remoteAddress,remotePort = m:receivefrom()
		if (not cmd) then
			print(string.format("[%d][wgtrf] err", os.millisecond()), remoteAddress)
			break
		end
		print(string.format("[%d][wgtrf] receivefrom(%s:%d), data:", os.millisecond(), remoteAddress, remotePort), cmd)
	
		local cmd_id,cmd_data = cmd:match("^([^ ]+) (.+)$")
		if (cmd_id and cmd_data) then
			local id_pos = cmd_id:find("-")
			if (not id_pos) then -- front
				local peerIP = cmd_data
				if (cmd_id:find("^ping")) then
					local cmd2 = string.format("%s-%s-%d %s", cmd_id, remoteAddress, remotePort, remoteAddress)
					print(string.format("[%d][wgtrf] sendto(%s:%d), data:", os.millisecond(), peerIP, port), cmd2)
					assert(m:sendto(cmd2, peerIP, port))
				else
					--执行查询指令
					local p = io.popen(cmd_show, "r")
					local stdout = p:read("*a")
					p:close()

					local conf = parseConf(stdout)
					local own = conf[remoteAddress]
					local peer = conf[peerIP]
					if (own and peer) then
						local msg1 = string.format("%s-%s-%d ", cmd_id, remoteAddress, remotePort) .. own["public key"]
						local msg2 = cmd_id .. " " .. peer["public key"]
						if (cmd_id == "remove") then
							msg1 = msg1 .. " remove"
							msg2 = msg2 .. " remove"
						else
							msg1 = msg1 .. (" endpoint " .. own["endpoint"] .. " persistent-keepalive 25 allowed-ips " .. own["allowed ips"])
							msg2 = msg2 .. (" endpoint " .. peer["endpoint"] .. " persistent-keepalive 25 allowed-ips " .. peer["allowed ips"])
						end
						print(string.format("[%d][wgtrf] sendto(%s:%d), data:", os.millisecond(), peerIP, port), msg1)
						assert(m:sendto(msg1, peerIP, port))
						print(string.format("[%d][wgtrf] sendto(%s:%d), data:", os.millisecond(), remoteAddress, remotePort), msg2)
						assert(m:sendto(msg2, remoteAddress, remotePort))
					end					
				end
			else -- end
				local address2,port2 = cmd_id:match("([^%-]+)%-(.+)$", id_pos)
				local cmd2 = string.format("%s-%s-%d %s %s", cmd_id:sub(1,id_pos-1), remoteAddress, remotePort, cmd_data, address2)
				print(string.format("[%d][wgtrf] sendto(%s:%s), data:", os.millisecond(), address2, port2), cmd2)
				assert(m:sendto(cmd2, address2, tonumber(port2)))
			end
		end	--if
	end --while

	m:close()

	print(string.format("[%d][wgtrf] close", os.millisecond()))
end

local function daemon(arg1, arg2, arg3, arg4)
	while(true) do
		print(string.format("[%d][wgtrf] daemon", os.millisecond()))
		local ok,err = pcall(start, arg1, arg2, arg3, arg4)
		if (not ok) then
			print(string.format("[%d][wgtrf] err", os.millisecond))
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
