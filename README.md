# ip_manage.sh
## 通过curl执行
```bash
### 获取当前IP配置
curl -s https://cdn.jsdelivr.net/gh/marsbasex/d/ip_manage.sh | sudo bash -s get

### 自动固定当前IP配置
curl -s https://cdn.jsdelivr.net/gh/marsbasex/d/ip_manage.sh | sudo bash -s autostatic

### 固定指定IP配置
curl -s https://cdn.jsdelivr.net/gh/marsbasex/d/ip_manage.sh | sudo bash -s static <ip/mask> <gateway> <dns,dns...>
示例：
curl -s https://cdn.jsdelivr.net/gh/marsbasex/d/ip_manage.sh | sudo bash -s static 10.10.10.201/24 10.10.10.1 233.5.5.5,119.29.29.29

### 恢复固定前的IP配置
curl -s https://cdn.jsdelivr.net/gh/marsbasex/d/ip_manage.sh | sudo bash -s recover

### 删除所有当前IP配置，使用dhcp自动获取
curl -s https://cdn.jsdelivr.net/gh/marsbasex/d/ip_manage.sh | sudo bash -s dhcp
```

## 下载脚本后执行
```bash
### 下载脚本到指定路径
curl -s https://cdn.jsdelivr.net/gh/marsbasex/d/ip_manage.sh --output $HOME/ip_manage.sh
### 执行示例 (参考说明：通过curl执行)
bash $HOME/ip_manage.sh get
bash $HOME/ip_manage.sh autostatic
bash $HOME/ip_manage.sh static 10.10.10.201/24 10.10.10.1 233.5.5.5,119.29.29.29
bash $HOME/ip_manage.sh recover
bash $HOME/ip_manage.sh dhcp
```
