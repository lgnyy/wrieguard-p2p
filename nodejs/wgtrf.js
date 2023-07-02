const {exec} = require("child_process");
const dgram = require("dgram");
const udpServer = dgram.createSocket("udp4");
const options = {port: (process.argv[4] || 33055), address: (process.argv[3] || "0.0.0.0")}

const cmd_show = "wg show " + (process.argv[2] || "wg0");


function parseConf(conf){
	let result={}, tmp;
	let lines = conf.split("\n");
	for (const line of lines) {
		if (line.startsWith("peer: ")){
			tmp = {"public key" : line.substr(6)};
		}else if (!tmp){
			continue;
		}else if (line.startsWith("  endpoint: ")){
			tmp["endpoint"] = line.substr(12);
		}else if (line.startsWith("  allowed ips: ")){
			tmp["allowed ips"] = line.substr(15).replace(/ /g, "");
		}else if (line === ""){
			let ip = tmp["allowed ips"];
			result[ip.substring(0, ip.indexOf("/"))] = tmp;
		}
	}
	return result;
}

// pingXXX  peerIP -> (pingXXX-ip-port reqIP -> pingXXX-ip-port pong) -> pingXXX pong
// setxXXX  peerIP -> (setxXXX-ip-port publicKey... -> setxXXX-ip-port success) ->setxXXX success reqIP
udpServer.on("message", function(msg, rinfo) {
	const cmd = msg.toString();
	console.log(new Date().getTime(), `udp recv(${rinfo.address}:${rinfo.port}):`, cmd);
	
	const cmd_ps = cmd.split(" ", 2);
	const id_ps = cmd_ps[0].split("-");
	if (id_ps.length === 1){ // front
		const peerIP = cmd_ps[1];
		if (cmd_ps[0].startsWith("ping")){
			const cmd2 = `${cmd_ps[0]}-${rinfo.address}-${rinfo.port} ${peerIP}`;
			console.log(new Date().getTime(), `udp send(${peerIP}:${options.port}):`, cmd2);
			udpServer.send(cmd2, options.port, peerIP);		
		}else{
			// 执行查询指令
			exec(cmd_show, (error, stdout, stderr) => {
				//console.log(new Date().getTime(), `stdout: ${stdout}`);
				console.error(new Date().getTime(), `stderr: ${stderr}`);
				if (error) {
					console.error(`exec error: ${error}`);
					udpServer.send(cmd_ps[0] + " fail " + error, rinfo.port,rinfo.address);
				}else{
					let conf = parseConf(stdout);
					let own = conf[rinfo.address];
					let peer = conf[peerIP];
					if (own && peer){
						let msg1 = `${cmd_ps[0]}-${rinfo.address}-${rinfo.port} ` + own["public key"];
						let msg2 = cmd_ps[0] + " " + peer["public key"];
						if (cmd_ps[0].startsWith("remove")){
							msg1 += " remove";
							msg2 += " remove";
						}else{
							msg1 += (" endpoint " + own["endpoint"] + " persistent-keepalive 25 allowed-ips " + own["allowed ips"]);
							msg2 += (" endpoint " + peer["endpoint"] + " persistent-keepalive 25 allowed-ips " + peer["allowed ips"]);
						}
						
						console.log(new Date().getTime(), `udp send(${peerIP}:${options.port}):`, msg1);
						udpServer.send(msg1, options.port, peerIP);
						
						console.log(new Date().getTime(), `udp send(${rinfo.address}:${options.port}):`, msg2);
						udpServer.send(msg2, rinfo.port, rinfo.address);
					}
				}			
			});			
		}			
	}else{ // end
		const cmd2 = `${id_ps[0]}-${rinfo.address}-${rinfo.port} ${cmd_ps[1]} ${id_ps[1]}`;
		console.log(new Date().getTime(), `udp send(${id_ps[1]}:${id_ps[2]}):`, cmd2);
		udpServer.send(cmd2, parseInt(id_ps[2]), id_ps[1]);	
	}
});

udpServer.bind(options);
console.log(new Date().getTime(), `udp server(${options.address}:${options.port}) start...`);