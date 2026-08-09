<div align="center">

# ⚡ POKIDEX
### Next-Generation Neural Signal Simulation & Biomedical Research Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](http://makeapullrequest.com)

**POKIDEX** is an ultra-high performance Flutter-based biomedical research dashboard and simulation platform. Built for biopotential signal synthesis, real-time EEG/ERP telemetry streaming, spectral band analysis, and ground-truth event tracking.

[Explore Features](#-key-features) • [System Architecture](#-system-architecture) • [Getting Started](#-getting-started) • [Documentation](#-module-breakdown)

</div>

---

## 📖 Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Module Breakdown](#-module-breakdown)
  - [1. Real-Time Signal Engines](#1-real-time-signal-engines)
  - [2. Multi-Protocol Transport Layer](#2-multi-protocol-transport-layer)
  - [3. Deep Analytics & Spectral Breakdown](#3-deep-analytics--spectral-breakdown)
  - [4. Scenario & Ground-Truth Logging](#4-scenario--ground-truth-logging)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Tech Stack & Dependencies](#-tech-stack--dependencies)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**POKIDEX** bridges the gap between raw neural data simulation and live biomedical monitoring terminals. Designed with a sleek cyber-dark aesthetic and optimized for high frame rates, POKIDEX provides researchers, neural engineers, and developers with a complete toolchain to configure complex EEG/ERP signals, broadcast telemetry across local networks or BLE peripherals, and visualize dynamic biopotentials in real time.

---

## ✨ Key Features

- 🧠 **Multi-Engine Signal Generator**: Real-time synthesis of multi-frequency EEG (Alpha, Beta, Theta, Delta, Gamma) and ERP (Event-Related Potentials) waveforms with custom noise and artifacts.
- ⚡ **Multi-Protocol Telemetry Transport**: Dynamic data streaming via **WebSockets** (shelf, shelf_web_socket) and native **Bluetooth Low Energy (BLE)** peripheral simulation.
- 📊 **Interactive Biopotential Charts**: Ultra-fluid waveform dynamic graphing using l_chart tuned for sub-millisecond data updates.
- 🎯 **Scenario & Ground-Truth System**: Preset simulation scenarios (e.g., Focus State, Sleep Stages, Epileptic Spikes, Cognitive Load) with automated ground-truth logging and export capabilities.
- 🎨 **Modern Cyber-Dark UI**: Designed with glassmorphism, responsive navigation shells, customizable channel gains, and stateful dark-mode themes.
- 💾 **Session Logging & Export**: Save recording snapshots, export spectral analysis logs, and share telemetry outputs effortlessly via native platform adapters.

---

## 🏗️ System Architecture

`mermaid
graph TD
    subgraph "Signal Engine Layer"
        SE[SignalEngine Base] --> EEG[EEGEngine]
        SE --> ERP[ERPEngine]
        SE --> SC[ScenarioEngine]
    end

    subgraph "State & Event Management"
        SP[SignalProvider]
        ASP[AppStateProvider]
        GTS[GroundTruthService]
    end

    subgraph "Transport & Streaming Layer"
        MST[MultiSignalTransport]
        WST[WebSocketTransport]
        BLE[BLEPeripheralTransport]
    end

    subgraph "UI Dashboard Shell"
        HS[HomeScreen & Controls]
        WS[WaveformChart Displays]
        AS[AnalyticsScreen / FFT]
        CS[ConnectionScreen / Server Status]
    end

    EEG -->|Raw Frames| SP
    ERP -->|Spikes/Artifacts| SP
    SC -->|Simulated Triggers| GTS
    GTS -->|Ground Truth Logs| SP

    SP -->|Stream Payload| MST
    MST --> WST
    MST --> BLE

    SP -->|Notify Listeners| HS
    SP -->|Telemetry Points| WS
    SP -->|Band Frequencies| AS
    WST -->|Local Network Sockets| CS
`

---

## 🔍 Module Breakdown

### 1. Real-Time Signal Engines
- **EEG Engine** (lib/engines/eeg_engine.dart): Configures continuous neural oscillation channels across standard brainwave frequencies.
- **ERP Engine** (lib/engines/erp_engine.dart): Generates stimulus-locked cognitive spikes (P300, N200, N400) for event-related potential experiments.
- **Scenario Engine** (lib/engines/scenario_engine.dart): Simulates complex cognitive state transitions and physiological conditions over time.

### 2. Multi-Protocol Transport Layer
- **WebSocket Server** (lib/transport/websocket_transport.dart): Spins up an embedded HTTP/WS server via Dart's shelf package for low-latency network telemetry broadcast.
- **BLE Peripheral Transport** (lib/transport/ble_peripheral_transport.dart): Simulates a hardware EEG headset broadcasting bio-signals over Bluetooth Low Energy.

### 3. Deep Analytics & Spectral Breakdown
- **Spectral Decomposition**: Calculates live relative power percentages for Delta (1-4 Hz), Theta (4-8 Hz), Alpha (8-12 Hz), Beta (12-30 Hz), and Gamma (30+ Hz) bands.
- **Signal Quality Metrics**: Real-time signal-to-noise ratio (SNR) computation and channel impedance monitoring.

### 4. Scenario & Ground-Truth Logging
- **Ground-Truth Logger** (lib/services/ground_truth_service.dart): Records time-stamped events, trigger indices, and signal annotations to evaluate classification models.

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed on your local development machine:

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (Version >= 3.3.0)
- **[Dart SDK](https://dart.dev/get-dart)** (Version >= 3.3.0 < 4.0.0)
- **Git**

### Installation

1. **Clone the Repository**
   `ash
   git clone https://github.com/Barathwaj2006/Pokidex.git
   cd Pokidex
   `

2. **Fetch Dependencies**
   `ash
   flutter pub get
   `

3. **Launch the Application**
   `ash
   # Run on Desktop (Windows/macOS/Linux) or Web/Mobile
   flutter run
   `

---

## 🛠️ Tech Stack & Dependencies

| Package | Purpose |
| :--- | :--- |
| **lutter** | Multi-platform UI framework |
| **provider** | Reactive state management layer |
| **l_chart** | High-performance dynamic biopotential plotting |
| **shelf & shelf_web_socket** | Embedded WebSocket & HTTP telemetry server |
| **google_fonts** | Modern typography system |
| **uuid** | Unique payload and session ID generation |
| **path_provider & share_plus** | Local telemetry file storage & native sharing |

---

## 🤝 Contributing

Contributions are what make the open-source community an incredible place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. **Fork** the Repository
2. **Create** your Feature Branch (git checkout -b feature/AmazingFeature)
3. **Commit** your Changes (git commit -m 'Add some AmazingFeature')
4. **Push** to the Branch (git push origin feature/AmazingFeature)
5. **Open** a Pull Request

---

## 📜 License

Distributed under the **MIT License**. See LICENSE for more information.

<div align="center">
  <sub>Built with ❤️ by <a href="https://github.com/Barathwaj2006">Barathwaj</a> for Neural Signal Simulation & Biomedical Research.</sub>
</div>