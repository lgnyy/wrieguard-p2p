# wrieguard-p2p
交换wireguard的peer连接信息，实现p2p

具体: 在服务器上执行wg show wg0，获取两端的peer信息；在对端上执行 wg set wg0 peer ...
总是通过服务端转发配置指令，当p2p失败时，可以删除对方peer信息，恢复通信。

```sh
sudo wg show wg0
```
输出如下：（wg0的IP为10.10.0.1）
```txt
interface: wg0
  public key: yQKSxj7F/HoTIBAwCA/jtYcyCWMqX8gvMq7AomjxU2A=
  private key: (hidden)
  listening port: 10001

peer: nET2q2OK2sgovco21Joscckg31CcN6s8xy41nyle9Dg=
  endpoint: 43.129.234.142:10002
  allowed ips: 10.10.0.2/32

peer: bdFY7I+kVDMnFP/EoO306nghee4AGI2cSGZ2V9EFJQQ=
  endpoint: 3.33.152.147:10003
  allowed ips: 10.10.0.3/32
```

以下用nodejs、lua脚本实现，修改相应的ip和port即可。

- 

## nodejs
------------

### 对端（nET2q2OK2sgovco21Joscckg31CcN6s8xy41nyle9Dg=）

```bash
    sudo node ./wgsvr.js wg0 10.10.0.2 33055
```
  
### 服务器（转发）

```bash
  sudo node ./wgtrf.js wg0 10.10.0.1 33055
```

### 客户端（bdFY7I+kVDMnFP/EoO306nghee4AGI2cSGZ2V9EFJQQ=）（管理员）

更新p2p连接信息（带心跳），关闭进程自动删除p2p连接信息

```bash
  node client.js wg0 10.10.0.1 33055 setx 10.10.0.2
```

更新p2p连接信息

```bash
  node client.js wg8 10.10.0.1 33055 set0 10.10.0.2
```

删除p2p连接信息

```bash
  node client.js wg8 10.10.0.1 33055 remove 10.10.0.2
```


## lua(依赖luasocket)
------------

### 对端

```bash
    sudo lua ./wgsvr.lua wg0 10.10.0.2 33055
```
  
### 服务器（转发）

```bash
    sudo lua ./wgtrf.lua wg0 10.10.0.1 33055
```

### 客户端（管理员）

更新p2p连接信息（带心跳），关闭进程自动删除p2p连接信息

```bash
    lua client.lua wg8 10.10.0.1 33055 setx 10.10.0.2
```

更新p2p连接信息

```bash
    lua client.lua wg8 10.10.0.1 33055 set0 10.10.0.2
```

删除p2p连接信息

```bash
    lua client.lua wg8 10.10.0.1 33055 remove 10.10.0.2
```

