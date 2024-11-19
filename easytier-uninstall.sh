#!/bin/bash

# 卸载 EasyTier 脚本

# 安装路径（默认路径，你可以根据需要修改）
INSTALL_PATH='/opt/easytier'

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
  echo -e "\r\n\033[1;31m错误: 请以 root 用户运行此脚本！\033[0m\r\n"
  exit 1
fi

# 提示用户卸载信息
echo -e "\r\n\033[1;31m----------------------NOTICE----------------------\033[0m\r\n"
echo " 正在卸载 EasyTier..."
echo " 请确保你已经备份了所有重要的配置文件。"
echo -e "\r\n\033[1;31m-------------------------------------------------\033[0m\r\n"

# 检查是否存在 EasyTier 的安装文件
if [ ! -d "$INSTALL_PATH" ]; then
  echo -e "\r\n\033[1;31m错误: EasyTier 没有在指定路径找到。无法卸载！\033[0m\r\n"
  exit 1
fi

# 停止并禁用 EasyTier 服务
echo "停止 EasyTier 服务..."
systemctl stop "easytier@*" >/dev/null 2>&1
systemctl disable "easytier@*" >/dev/null 2>&1

# 删除 EasyTier 安装文件和相关配置
echo "删除 EasyTier 文件和配置..."

# 删除安装路径及相关文件
rm -rf "$INSTALL_PATH"  # 删除 EasyTier 安装目录

# 删除 systemd 服务文件
rm -rf /etc/systemd/system/easytier@.service
rm -rf /etc/systemd/system/easytier.service

# 删除 EasyTier 二进制文件
rm -rf /usr/sbin/easytier-core
rm -rf /usr/sbin/easytier-cli

# 删除配置文件（如果有）
rm -rf "$INSTALL_PATH/config"  # 删除配置文件目录

# 清理 systemd 配置
systemctl daemon-reload

# 删除其他可能存在的快捷方式和符号链接
rm -rf /usr/bin/easytier-core
rm -rf /usr/bin/easytier-cli

# 打印卸载完成的提示
echo -e "\r\n\033[1;32mEasyTier 已成功卸载！\033[0m\r\n"

exit 0
