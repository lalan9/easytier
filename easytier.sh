#!/bin/bash

# This script copy from alist , Thank for it!

SKIP_FOLDER_VERIFY=false
SKIP_FOLDER_FIX=false

COMMEND=$1
shift

# Check path
if [[ "$#" -ge 1 && ! "$1" == --* ]]; then
    INSTALL_PATH=$1
    shift
fi

# Check other option
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-folder-verify) SKIP_FOLDER_VERIFY=true ;;
        --skip-folder-fix) SKIP_FOLDER_FIX=true ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$INSTALL_PATH" ]; then
    INSTALL_PATH='/opt/easytier'
fi

if [[ "$INSTALL_PATH" == */ ]]; then
    INSTALL_PATH=${INSTALL_PATH%?}
fi

if ! $SKIP_FOLDER_FIX && ! [[ "$INSTALL_PATH" == */easytier ]]; then
    INSTALL_PATH="$INSTALL_PATH/easytier"
fi

echo INSTALL PATH : $INSTALL_PATH
echo SKIP FOLDER FIX : $SKIP_FOLDER_FIX
echo SKIP FOLDER VERIFY : $SKIP_FOLDER_VERIFY

RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
SHAN='\e[1;33;5m'
RES='\e[0m'

# check if unzip is installed
if ! command -v unzip >/dev/null 2>&1; then
  echo -e "\r\n${RED_COLOR}Error: unzip is not installed${RES}\r\n"
  exit 1
fi

# check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
  echo -e "\r\n${RED_COLOR}Error: curl is not installed${RES}\r\n"
  exit 1
fi

echo -e "\r\n${RED_COLOR}----------------------NOTICE----------------------${RES}\r\n"
echo " This is a temporary script to install EasyTier "
echo " EasyTier requires a dedicated empty folder to install"
echo " EasyTier is a developing product and may have some issues "
echo " Using EasyTier requires some basic skills "
echo " You need to face the risks brought by using EasyTier at your own risk "
echo -e "\r\n${RED_COLOR}-------------------------------------------------${RES}\r\n"

# Get platform
if command -v arch >/dev/null 2>&1; then
  platform=$(arch)
else
  platform=$(uname -m)
fi

case "$platform" in
  amd64 | x86_64)
    ARCH="x86_64"
    ;;
  arm64 | aarch64 | *armv8*)
    ARCH="aarch64"
    ;;
  *armv7*)
    ARCH="armv7"
    ;;
  *arm*)
    ARCH="arm"
    ;;
  mips)
    ARCH="mips"
    ;;
  mipsel)
    ARCH="mipsel"
    ;;
  *)
    ARCH="UNKNOWN"
    ;;
esac

# support hf
if [[ "$ARCH" == "armv7" || "$ARCH" == "arm" ]]; then
  if cat /proc/cpuinfo | grep Features | grep -i 'half' >/dev/null 2>&1; then
    ARCH=${ARCH}hf
  fi
fi

echo -e "\r\n${GREEN_COLOR}Your platform: ${ARCH} (${platform}) ${RES}\r\n" 1>&2

if [ "$(id -u)" != "0" ]; then
  echo -e "\r\n${RED_COLOR}This script requires run as Root !${RES}\r\n" 1>&2
  exit 1
elif [ "$ARCH" == "UNKNOWN" ]; then
  echo -e "\r\n${RED_COLOR}Opus${RES}, this script do not support your platform\r\nTry ${GREEN_COLOR}install by band${RES}\r\n"
  exit 1
elif ! command -v systemctl >/dev/null 2>&1; then
  echo -e "\r\n${RED_COLOR}Opus${RES}, your Linux do not support systemctl\r\nTry ${GREEN_COLOR}install by band${RES}\r\n"
  exit 1
fi

CHECK() {
  if ! $SKIP_FOLDER_VERIFY; then
    if [ -f "$INSTALL_PATH/easytier-core" ]; then
      echo "There is EasyTier in $INSTALL_PATH. Please choose another path or use \"update\""
      echo -e "Or use Try ${GREEN_COLOR}--skip-folder-verify${RES} to skip"
      exit 0
    fi
  fi
  if [ ! -d "$INSTALL_PATH/" ]; then
    mkdir -p $INSTALL_PATH
  else
    # Check whether path is empty
    if ! $SKIP_FOLDER_VERIFY; then
      if [ -n "$(ls -A $INSTALL_PATH)" ]; then
        echo "EasyTier requires to be installed in an empty directory. Please choose an empty path"
        echo -e "Or use Try ${GREEN_COLOR}--skip-folder-verify${RES} to skip"
        echo -e "Current path: $INSTALL_PATH ( use ${GREEN_COLOR}--skip-folder-fix${RES} to disable folder fix )"
        exit 1
      fi
    fi
  fi
}

INSTALL() {
  # Specify the fixed version you want to download
  VERSION="v2.0.3"
  DOWNLOAD_URL="http://ip:3988/easytier-linux-x86_64-${VERSION}.zip"

  # Download
  echo -e "\r\n${GREEN_COLOR}Downloading EasyTier $VERSION ...${RES}"
  rm -rf /tmp/easytier_tmp_install.zip
  curl -L $DOWNLOAD_URL -o /tmp/easytier_tmp_install.zip $CURL_BAR
  
  # Unzip resource
  echo -e "\r\n${GREEN_COLOR}Unzip resource ...${RES}"
  unzip -o /tmp/easytier_tmp_install.zip -d $INSTALL_PATH/
  mkdir $INSTALL_PATH/config
  mv $INSTALL_PATH/easytier-linux-${ARCH}/* $INSTALL_PATH/
  rm -rf $INSTALL_PATH/easytier-linux-${ARCH}/
  chmod +x $INSTALL_PATH/easytier-core $INSTALL_PATH/easytier-cli
  if [ -f $INSTALL_PATH/easytier-core ] || [ -f $INSTALL_PATH/easytier-cli ]; then
    echo -e "${GREEN_COLOR} Download successfully! ${RES}"
  else
    echo -e "${RED_COLOR} Download failed! ${RES}"
    exit 1
  fi
}

INIT() {
  if [ ! -f "$INSTALL_PATH/easytier-core" ]; then
    echo -e "\r\n${RED_COLOR}Opus${RES}, unable to find EasyTier\r\n"
    exit 1
  fi

HOSTNAME=$(hostname)
  # Create default blank file config
  cat >$INSTALL_PATH/config/default.conf <<EOF
instance_name = "$HOSTNAME"
dhcp = false
dhcp = false
listeners = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
    "wg://0.0.0.0:11011",
    "ws://0.0.0.0:11011/",
    "wss://0.0.0.0:11012/",
    "tcp://[::]:11010",
    "udp://[::]:11010",
    "wg://[::]:11011",
    "ws://[::]:11011/",
    "wss://[::]:11012/", 
]
exit_nodes = []
peer = []
rpc_portal = "0.0.0.0:15888"
rpc_portal_ipv6 = "[::]:15888"

[network_identity]
network_name = "XA-default"
network_secret = ""

[flags]
default_protocol = "wss"
dev_name = "XA-tun0"
enable_encryption = true
enable_ipv6 = true
mtu = 1400
latency_first = false
enable_exit_node = true
no_tun = false
use_smoltcp = false
foreign_network_whitelist = "*"
disable_p2p = false
relay_all_peer_rpc = true
EOF

  # Create systemd
  cat >/etc/systemd/system/easytier@.service <<EOF
[Unit]
Description=EasyTier Service
Wants=network.target
After=network.target network.service

[Service]
Type=simple
WorkingDirectory=$INSTALL_PATH
ExecStart=$INSTALL_PATH/easytier-core -c $INSTALL_PATH/config/%i.conf

[Install]
WantedBy=multi-user.target
EOF

  # Startup
  systemctl daemon-reload
  systemctl enable easytier@default >/dev/null 2>&1
  systemctl start easytier@default

  # Add link
  ln -s $INSTALL_PATH/easytier-core /usr/sbin/easytier
}

SUCCESS() {
  echo -e "\r\n${GREEN_COLOR} EasyTier installed successfully! ${RES}"
  echo -e "Service Started. Use ${GREEN_COLOR}systemctl status easytier@default${RES} to check"
}

# The temp directory must exist
if [ ! -d "/tmp" ]; then
  mkdir -p /tmp
fi

echo $COMMEND

if [ "$COMMEND" = "uninstall" ]; then
  UNINSTALL
elif [ "$COMMEND" = "update" ]; then
  UPDATE
elif [ "$COMMEND" = "install" ]; then
  CHECK
  INSTALL
  INIT
  if [ -f "$INSTALL_PATH/easytier-core" ]; then
    SUCCESS
  else
    echo -e "${RED_COLOR} Install fail, try install by hand${RES}"
  fi
else
  echo -e "${RED_COLOR} Error Command ${RES}\n\r"
  echo " ALLOW:"
  echo -e "\n\r${GREEN_COLOR} install, uninstall, update ${RES}"
fi

rm -rf /tmp/easytier_tmp_*
