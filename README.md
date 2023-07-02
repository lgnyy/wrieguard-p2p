# wrieguard-p2p
交换wireguard的peer连接信息，实现p2p

## nodejs
### 对端
  sudo node ./wgsvr.js wg0 10.0.8.27 33055
### 服务器（转发）
  sudo node ./wgtrf.js wg0 10.0.8.1 33055
### 客户端（管理员）
;更新p2p连接信息（带心跳）
  node ./client.js wg8 10.0.8.1 33055 setx 10.0.8.27
;更新p2p连接信息
  node ./client.js wg8 10.0.8.1 33055 set0 10.0.8.27
;删除p2p连接信息
  node ./client.js wg8 10.0.8.1 33055 remove 10.0.8.27
