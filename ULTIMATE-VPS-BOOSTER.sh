#!/bin/bash

#========= VPS BOOSTER MENU =========#
# Fully Compatible with Debian & Ubuntu
# Run as root
#====================================#

clear
echo "========================================"
echo "     ULTIMATE VPS BOOSTER (MENU)"
echo " Debian & Ubuntu - Performance + Speed"
echo "========================================"
echo "Choose your optimization level:"
echo "1) Basic Boost"
echo "2) Intermediate Boost"
echo "3) Advanced Boost"
echo "4) Ultra Boost (All-in-One)"
echo "========================================"
read -p "Enter your choice (1-4): " choice

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use sudo."
   exit 1
fi

# Function: Create 50GB Swap
create_swap() {
    echo "Creating 50GB swap file..."
    swapoff -a
    rm -f /swapfile
    fallocate -l 50G /swapfile || dd if=/dev/zero of=/swapfile bs=1G count=50
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
}

# Function: Basic Tuning
basic_boost() {
    echo "Applying Basic Boost..."
    apt update && apt upgrade -y
    apt install -y haveged ufw preload htop curl wget
    systemctl enable haveged --now
    systemctl enable preload --now
    sysctl -w net.ipv4.tcp_syncookies=1
    sysctl -w net.ipv4.ip_forward=1
    create_swap
    echo "Basic boost complete!"
}

# Function: Intermediate Tuning
intermediate_boost() {
    basic_boost
    echo "Applying Intermediate Network Boost (BBR + Buffers)..."
    modprobe tcp_bbr
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    cat <<EOF >> /etc/sysctl.conf

# BBR & Buffers
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOF
    sysctl -p
    echo "Intermediate boost complete!"
}

# Function: Advanced Tuning
advanced_boost() {
    intermediate_boost
    echo "Applying Advanced CPU & Disk I/O Optimizations..."
    apt install -y irqbalance tuned
    systemctl enable irqbalance --now
    tuned-adm profile throughput-performance

    for disk in $(lsblk -d -n -o NAME); do
        echo "mq-deadline" > /sys/block/$disk/queue/scheduler 2>/dev/null
    done

    echo "* soft nofile 1048576" >> /etc/security/limits.conf
    echo "* hard nofile 1048576" >> /etc/security/limits.conf
    ulimit -n 1048576

    echo "Advanced boost complete!"
}

# Function: Ultra Boost (All-in-One)
ultra_boost() {
    advanced_boost
    echo "Applying Ultra Network Tuning..."
    cat <<EOF >> /etc/sysctl.conf

# Extra TCP Tweaks
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_no_metrics_save=1

# Disable IPv6 (optional)
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

    sysctl -p

    # UFW Basic Protection
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw --force enable

    apt autoremove -y
    apt clean

    echo "Ultra Boost complete! VPS is maxed out!"
}

# Run selection
case $choice in
    1)
        basic_boost
        ;;
    2)
        intermediate_boost
        ;;
    3)
        advanced_boost
        ;;
    4)
        ultra_boost
        ;;
    *)
        echo "Invalid choice. Please run the script again and select 1-4."
        ;;
esac

echo "========================================"
echo " VPS Optimization Level $choice Done!"
echo " Reboot recommended for full effect."
echo "========================================"
