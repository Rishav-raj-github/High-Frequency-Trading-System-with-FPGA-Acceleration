# Installation Guide

## High-Frequency Execution System with FPGA Acceleration

This guide provides comprehensive instructions for installing and configuring the HFT FPGA system.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Hardware Requirements](#hardware-requirements)
3. [Software Dependencies](#software-dependencies)
4. [FPGA Setup](#fpga-setup)
5. [System Configuration](#system-configuration)
6. [Building from Source](#building-from-source)
7. [Installation](#installation)
8. [Verification](#verification)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Operating System

**Recommended**: Ubuntu 20.04 LTS or 22.04 LTS with RT kernel

```bash
# Install RT kernel (optional but recommended for low latency)
sudo apt-get install linux-image-rt-amd64
sudo reboot
```

### User Permissions

You'll need sudo access for:
- Installing system packages
- Configuring huge pages
- Setting up network interfaces
- Loading FPGA bitstreams

---

## Hardware Requirements

### Minimum Requirements

| Component | Specification |
|-----------|---------------|
| **CPU** | Intel Xeon Scalable (6+ cores) or AMD EPYC |
| **RAM** | 64GB DDR4-2666 or higher |
| **FPGA** | Xilinx Alveo U250 or Intel Stratix 10 GX |
| **Network** | 10GbE NIC with kernel bypass support |
| **Storage** | 500GB NVMe SSD |

### Recommended Requirements

| Component | Specification |
|-----------|---------------|
| **CPU** | Intel Xeon Platinum 8300 series (16+ cores) |
| **RAM** | 128GB DDR4-3200 with ECC |
| **FPGA** | Xilinx Alveo U280 with HBM2 |
| **Network** | 25GbE Solarflare/Xilinx NIC |
| **Storage** | 1TB NVMe SSD (PCIe 4.0) |

### FPGA Compatibility

**Supported Xilinx FPGAs:**
- Alveo U250
- Alveo U280
- Alveo U50
- Kintec UltraScale+ (custom boards)

**Supported Intel FPGAs:**
- Stratix 10 GX/SX
- Agilex F-Series

---

## Software Dependencies

### System Packages

```bash
# Update package list
sudo apt-get update

# Essential build tools
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    autoconf \
    automake \
    libtool

# C++ libraries
sudo apt-get install -y \
    libboost-all-dev \
    libevent-dev \
    libssl-dev \
    libpthread-stubs0-dev

# Python dependencies (for scripts and ML)
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv

# Performance tools
sudo apt-get install -y \
    linux-tools-generic \
    hwloc \
    numactl \
    cpufrequtils
```

### FPGA Development Tools

#### Xilinx Vivado

```bash
# Download Vivado from Xilinx website (requires account)
wget https://www.xilinx.com/member/forms/download/xef.html?filename=Vivado_2023.1.tar.gz

# Extract and install
tar -xzf Vivado_2023.1.tar.gz
cd Vivado_2023.1
sudo ./xsetup

# Add to PATH
echo 'source /tools/Xilinx/Vivado/2023.1/settings64.sh' >> ~/.bashrc
source ~/.bashrc
```

#### Intel Quartus Prime (for Intel FPGAs)

```bash
# Download from Intel FPGA website
# Follow Intel's installation instructions

# Add to PATH
echo 'source /tools/intelFPGA_pro/23.1/hld/init_opencl.sh' >> ~/.bashrc
source ~/.bashrc
```

### Optional: DPDK for Kernel Bypass

```bash
# Install DPDK
wget https://fast.dpdk.org/rel/dpdk-21.11.tar.xz
tar xf dpdk-21.11.tar.xz
cd dpdk-21.11

# Build DPDK
meson build
cd build
ninja
sudo ninja install
sudo ldconfig
```

### Python Packages

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install packages
pip install --upgrade pip
pip install numpy pandas scikit-learn xgboost pyyaml
```

---

## FPGA Setup

### 1. Install FPGA Drivers

#### Xilinx XRT (Xilinx Runtime)

```bash
# Download XRT
wget https://www.xilinx.com/bin/public/openDownload?filename=xrt_202320.2.16.204_20.04-amd64-xrt.deb

# Install
sudo apt install ./xrt_202320.2.16.204_20.04-amd64-xrt.deb

# Install deployment platform
wget https://www.xilinx.com/bin/public/openDownload?filename=xilinx-u250-gen3x16-xdma_2023.1_2023_0507_2219-all.deb
sudo apt install ./xilinx-u250-gen3x16-xdma_2023.1_2023_0507_2219-all.deb
```

#### Verify FPGA Detection

```bash
# List FPGA devices
/opt/xilinx/xrt/bin/xbutil examine

# Expected output:
# Device [0]:
#   Shell: xilinx_u250_gen3x16_xdma_shell_4_1
#   PCIe: 0000:65:00.1
```

### 2. Configure Huge Pages

```bash
# Enable huge pages (required for high-performance memory access)
echo 2048 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Make permanent
echo "vm.nr_hugepages = 2048" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify
grep HugePages /proc/meminfo
```

### 3. CPU Isolation (Optional but Recommended)

```bash
# Edit GRUB configuration
sudo nano /etc/default/grub

# Add to GRUB_CMDLINE_LINUX:
# isolcpus=0-3 nohz_full=0-3 rcu_nocbs=0-3

# Update GRUB and reboot
sudo update-grub
sudo reboot
```

---

## System Configuration

### 1. Network Interface Setup

```bash
# Identify your execution network interface
ip link show

# Configure static IP (replace eth1 with your interface)
sudo nano /etc/netplan/01-netcfg.yaml
```

Add:
```yaml
network:
  version: 2
  ethernets:
    eth1:
      addresses:
        - 192.168.1.100/24
      mtu: 9000  # Jumbo frames
      optional: true
```

```bash
# Apply configuration
sudo netplan apply
```

### 2. System Tuning

```bash
# Disable CPU frequency scaling
sudo cpupower frequency-set -g performance

# Disable IRQ balance
sudo systemctl stop irqbalance
sudo systemctl disable irqbalance

# Set CPU affinity for IRQs
# (Script to be provided in scripts/setup_irq_affinity.sh)
```

### 3. Security Configuration

```bash
# Create configuration directory
mkdir -p config

# Copy example configuration
cp config/trading_config.yaml.example config/trading_config.yaml

# Edit with your settings (NEVER commit credentials!)
nano config/trading_config.yaml
```

---

## Building from Source

### 1. Clone Repository

```bash
git clone https://github.com/Rishav-raj-github/High-Frequency-Execution-System-with-FPGA-Acceleration.git
cd High-Frequency-Execution-System-with-FPGA-Acceleration
```

### 2. Build FPGA Bitstream (Optional - Pre-built available)

```bash
# This step takes 4-8 hours depending on design complexity
cd fpga
make build_hardware

# Or use pre-built bitstream
wget https://releases.example.com/trading_engine.bit
```

### 3. Build Software Components

```bash
# Create build directory
mkdir build
cd build

# Configure with CMake
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_FPGA=ON \
    -DENABLE_DPDK=OFF \
    -DBUILD_TESTS=ON \
    -DCMAKE_INSTALL_PREFIX=/opt/hft

# Build (use all CPU cores)
make -j$(nproc)

# Run tests
make test
```

---

## Installation

### 1. Install Built Components

```bash
# From build directory
sudo make install

# Verify installation
ls /opt/hft
```

### 2. Set Up Environment

```bash
# Add to PATH
echo 'export PATH=/opt/hft/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/hft/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

### 3. Load FPGA Bitstream

```bash
# Program FPGA
sudo /opt/xilinx/xrt/bin/xbutil program -d 0 -u fpga/build/trading_engine.xclbin

# Verify
/opt/xilinx/xrt/bin/xbutil examine -d 0
```

---

## Verification

### 1. Hardware Check

```bash
# Run hardware diagnostics
sudo hft_system_check --hardware

# Expected output:
# [✓] FPGA detected
# [✓] Network interface configured
# [✓] Huge pages enabled
# [✓] CPU isolation configured
```

### 2. Software Check

```bash
# Run software tests
hft_system_check --software

# Expected output:
# [✓] Configuration files valid
# [✓] All dependencies installed
# [✓] Permissions correct
```

### 3. Performance Benchmark

```bash
# Run latency benchmark
hft_benchmark --latency

# Expected results:
# Tick-to-trade latency: < 500ns
# Order processing: < 1μs
```

### 4. Test Market Data Feed

```bash
# Test with simulated data
hft_engine --mode simulation --duration 60

# Check logs
tail -f logs/hft_system.log
```

---

## Troubleshooting

### FPGA Not Detected

```bash
# Check PCIe devices
lspci | grep -i xilinx

# Reload drivers
sudo rmmod xocl
sudo modprobe xocl

# Check kernel logs
dmesg | grep -i fpga
```

### Network Issues

```bash
# Check interface status
ip link show eth1

# Test connectivity
ping -I eth1 192.168.1.1

# Check receive buffer
ethtool -g eth1
```

### Build Errors

```bash
# Clean build
rm -rf build
mkdir build
cd build

# Verbose build
cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON
make VERBOSE=1
```

### Permission Errors

```bash
# Add user to required groups
sudo usermod -a -G xrt,video,render $USER

# Re-login for changes to take effect
```

---

## Next Steps

After successful installation:

1. **Configure execution parameters**: Edit `config/trading_config.yaml`
2. **Review security settings**: See [SECURITY.md](SECURITY.md)
3. **Read usage guide**: See [README.md](README.md)
4. **Run backtests**: Test strategies with historical data
5. **Paper execution**: Validate system with paper execution

---

## Support

- **Issues**: [GitHub Issues](https://github.com/Rishav-raj-github/High-Frequency-Execution-System-with-FPGA-Acceleration/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Rishav-raj-github/High-Frequency-Execution-System-with-FPGA-Acceleration/discussions)
- **Documentation**: [Project Wiki](https://github.com/Rishav-raj-github/High-Frequency-Execution-System-with-FPGA-Acceleration/wiki)

---

**Installation Complete!** 🎉

You're now ready to configure and run the High-Frequency Execution System with FPGA Acceleration.
