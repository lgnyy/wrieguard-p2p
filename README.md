# wrieguard-p2p
交换wireguard的peer连接信息，实现p2p

具体: 在服务器上执行wg show wg0，获取两端的peer信息；在对端上执行 wg set wg0 peer ...

以下用nodejs、lua脚本实现

## nodejs
------------

### 对端

```bash
    sudo node ./wgsvr.js wg0 10.0.8.27 33055
```
  
### 服务器（转发）

```bash
  sudo node ./wgtrf.js wg0 10.0.8.1 33055
```

### 客户端（管理员）

更新p2p连接信息（带心跳）

```bash
  node client.js wg8 10.0.8.1 33055 setx 10.0.8.27
```

更新p2p连接信息

```bash
  node client.js wg8 10.0.8.1 33055 set0 10.0.8.27
```

删除p2p连接信息

```bash
  node client.js wg8 10.0.8.1 33055 remove 10.0.8.27
```


## lua(依赖luasocket)
------------

### 对端

```bash
    sudo lua ./wgsvr.lua wg0 10.0.8.27 33055
```
  
### 服务器（转发）

```bash
    sudo lua ./wgtrf.lua wg0 10.0.8.1 33055
```

### 客户端（管理员）

更新p2p连接信息（带心跳）

```bash
    lua client.lua wg8 10.0.8.1 33055 setx 10.0.8.27
```

更新p2p连接信息

```bash
    lua client.lua wg8 10.0.8.1 33055 set0 10.0.8.27
```

删除p2p连接信息

```bash
    lua client.lua wg8 10.0.8.1 33055 remove 10.0.8.27
```

