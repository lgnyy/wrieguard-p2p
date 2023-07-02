const {exec} = require("child_process");
const dgram = require("dgram");
const udpServer = dgram.createSocket("udp4");
const options = {port: (process.argv[4] || 33055), address: (process.argv[3] || "0.0.0.0")}
const cmd_pre = "wg set " + (process.argv[2] || "wg0") + " peer ";

const workInfos = {};

function removeWork(wis, publicKey){
	for (let key in wis){
		if (wis[key].publicKey === publicKey){
			clearInterval(wis[key].intervalID);
			delete wis[key];
			break;
		}
	}
}

// pingXXX-ip-port reqIP -> pingXXX-ip-port pong
// setxXXX-ip-port publicKey... -> setxXXX-ip-port success
udpServer.on("message", function(msg, rinfo) {
	const msg_s = msg.toString();
	console.log(new Date().getTime(), `udp recv(${rinfo.address}:${rinfo.port}):`, msg_s);
	
	const cmd_id = msg_s.substring(0, msg_s.indexOf(" ") + 1);
	const cmd_data = msg_s.substring(cmd_id.length);
	if (cmd_id.startsWith("ping")){
		const workInfo = workInfos[cmd_data];
		if (workInfo){
			workInfo.tickCount = 0;
		}
		udpServer.send(cmd_id + "pong", rinfo.port,rinfo.address);
	}else{
		// 执行新配置
		exec(cmd_pre + cmd_data, (error, stdout, stderr) => {
			console.log(new Date().getTime(), `stdout: ${stdout}`);
			console.error(new Date().getTime(), `stderr: ${stderr}`);
			if (error) {
				console.error(new Date().getTime(), `exec error: ${error}`);
				udpServer.send(cmd_id + "fail " + error, rinfo.port,rinfo.address);
			}else{
				udpServer.send(cmd_id + "success", rinfo.port,rinfo.address);
				
				const publicKey = cmd_data.substring(0, 44);
				removeWork(workInfos, publicKey);

				// 需要心跳维护
				if (!cmd_data.endsWith("remove") && !cmd_id.startsWith("set0")){
					const pos1 = cmd_data.indexOf("allowed-ips ") + 12;
					const pos2 = cmd_data.indexOf("/", pos1);
					const peerIP = cmd_data.substring(pos1, pos2);					
					
					var workInfo = {publicKey, tickCount:0};
					workInfo.intervalID = setInterval((wi) => {
						//console.log(new Date().getTime(), "setInterval"));
						wi.tickCount ++;
						if (wi.tickCount === 6){ // 30
							removeWork(workInfos, wi.publicKey)
							
							console.log(new Date().getTime(), "remove", wi.publicKey);
							exec(cmd_pre + wi.publicKey + " remove", (error, stdout, stderr) => console.error(`stderr: ${stderr}`));
						}
					}, 5000, workInfo);
					
					workInfos[peerIP] = workInfo;
					//console.log("workInfo", peerIP, workInfo); 
				}
			}
		});
	}
});

udpServer.bind(options);
console.log(new Date().getTime(), `udp server(${options.address}:${options.port}) start...`);
