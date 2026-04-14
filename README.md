# Hardware-Accelerated AES-128 RFID Authentication System

## 📌 Project Overview
This repository contains the RTL source code, microcontroller firmware, and documentation for a hybrid hardware-software secure access system. The project offloads computationally heavy cryptographic tasks (AES-128) to a dedicated FPGA hardware accelerator, achieving a strict 11-cycle encryption latency. The encrypted credentials are then relayed over a secure wireless Bluetooth link via ESP32 microcontrollers.

By decoupling the physical security (RFID acquisition) and cryptography (FPGA) from the wireless network layer (ESP32), the architecture ensures zero data corruption, protects against timing attacks, and operates with minimal power and resource footprints.

---

## 🏗️ System Architecture
The system consists of three primary stages:
1. **Data Acquisition:** An MFRC522 RFID reader scans MIFARE Classic 1K credentials via SPI.
2. **Hardware Encryption (FPGA):** The Basys 3 FPGA captures the 4-byte UID, pads it to 128 bits, and encrypts it using an unrolled 11-stage AES-128 pipeline.
3. **Wireless Relay (ESP32):** The ciphertext is serialized via UART (115200 baud) to a Master ESP32, which forwards the payload over Bluetooth to a remote Receiver ESP32 for final decryption and validation.

---

## 🛠️ Hardware Requirements
* **FPGA:** Digilent Basys 3 (Xilinx Artix-7 XC7A35T)
* **Microcontrollers:** 2x DOIT ESP32 DEVKIT V1
* **Peripherals:** MFRC522 RFID Reader module
* **Credentials:** MIFARE Classic 1K Cards / Keyfobs 
* **Wiring:** Standard male-to-female jumper wires

## 💻 Software & Tools
* **FPGA Synthesis & Simulation:** Xilinx Vivado (Tested on v2022.2+)
* **Microcontroller Firmware:** Arduino IDE (with ESP32 board manager installed)
* **Hardware Description Language:** Verilog (IEEE 1364-2001)

---

## 📂 Repository Structure
```text
├── fpga_rtl/                  # Verilog source files for the Basys 3
│   ├── aes128_top.v           # 11-stage unrolled AES cryptographic core
|   ├── aes_sbox.v             # Standard FIPS Look Up Table
|   ├── aes_mixcols.v
|   ├── aes_round.v
│   ├── uart_tx.v              # 128-bit UART Transmitter module
│   ├── rfid_aes_uart_top.v    # Top-level integration and FSM logic
│   └── constraints/
│       └── basys3_master.xdc  # Physical pin constraints (XDC)
├── esp32_firmware/            # Arduino sketches for the wireless nodes
│   ├── esp32_transmitter/     # Code for the Transmitter (Master) ESP32
│   └── esp32_receiver/        # Code for the Receiver (Slave) ESP32
├── docs/                      # Timing reports, QoR metrics, and schematics
└── README.md
