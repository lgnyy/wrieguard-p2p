const {exec} = require("child_process");
const dgram = require("dgram");
const udpClient = dgram.createSocket("udp4");
const options = {port: (process.argv[4] || 33055), address: (process.argv[3] || "10.0.8.1")} // 27
const cmd_pre = "wg set " + (process.argv[2] || "wg8") + " peer "
const message = (process.argv[5] || "setx") + " " + (process.argv[6] || "10.0.8.27");


console.log(new Date().getTime(), `udp send(${options.address}:${options.port}):`, message);
udpClient.send(message,options.port,options.address,function(err,bytes) {
	if (err){
		console.log("error", err);
	}
});

udpClient.on("message", function(msg, rinfo) {
	const cmd = msg.toString();
	console.log(new Date().getTime(), `udp recv(${rinfo.address}:${rinfo.port}):`, cmd);
	
	if (!cmd.startsWith("ping")){
		const pos = cmd.indexOf(" ");
		
		if (cmd.substring(0,pos).indexOf("-") < 0){
			exec(cmd_pre + cmd.substring(pos+1), function(error, stdout, stderr){
				console.log(`stdout: ${stdout}`);
				console.error(`stderr: ${stderr}`);
				if (error) {
					console.error(`exec error: ${error}`);
				}
				if (options.need_exit){
					process.exit();
				}
			});
		}else if (cmd.startsWith("setx")){
			const cmd_ps = cmd.split(" ");
			
			console.log("PLS press CTRL+C to exit...");
			setInterval((cc)=> {
				console.log(new Date().getTime(), `udp send(${options.address}:${options.port}):`, cc);
				console.log("PLS press CTRL+C to exit...");
				udpClient.send(cc, options.port, options.address);
			}, 10000, "ping " + message.split(" ")[1]);
		}else{	
			setTimeout(() => process.exit(), 5000);
		}
	}
});

process.on("SIGINT", ()=>{
	const cmd2 = "remove " + message.split(" ")[1];
	options.need_exit = true;
	console.log(new Date().getTime(), `udp send(${options.address}:${options.port}):`, cmd2);
	udpClient.send(cmd2,options.port,options.address);
});


