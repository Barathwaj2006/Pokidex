/**
 * NeuroSim BLE Client — Drop-in Web Bluetooth SDK for Pokidex
 * 
 * Supports:
 * - 250 Hz ultra-low-latency 13-byte compact binary streaming (`0xAA 0x01`)
 * - Fallback chunked JSON stream decoding
 * - Two-way remote control commands (PRESET:<id>, START, STOP, FORMAT:BIN)
 * 
 * Usage in NeuroSim Website (Vanilla JS / React / Vue):
 * ```js
 * import { PokidexBleClient } from './neurosim_ble_client.js';
 * 
 * const client = new PokidexBleClient();
 * client.onData((samples, seq) => {
 *   // samples is an array of 4 channels [Fp1, Fp2, O1, O2] in microvolts (uV)
 *   console.log(`Seq ${seq}:`, samples);
 * });
 * client.onStatus((status) => console.log('BLE Status:', status));
 * 
 * await client.connect();
 * await client.setPreset('p03'); // Cognitive Load
 * ```
 */

export const POKIDEX_SERVICE_UUID = '0000fe50-0000-1000-8000-00805f9b34fb';
export const POKIDEX_CHARACTERISTIC_UUID = '0000fe51-0000-1000-8000-00805f9b34fb';

export class PokidexBleClient {
  constructor() {
    this.device = null;
    this.server = null;
    this.characteristic = null;
    this.isConnected = false;
    this.dataCallbacks = [];
    this.statusCallbacks = [];
    this.chunkAssembly = new Map();
  }

  /**
   * Subscribes to real-time neural data samples
   * @param {function(samples: number[], sequence: number): void} callback
   */
  onData(callback) {
    this.dataCallbacks.push(callback);
  }

  /**
   * Subscribes to connection state changes
   * @param {function(status: string): void} callback
   */
  onStatus(callback) {
    this.statusCallbacks.push(callback);
  }

  _notifyStatus(status) {
    for (const cb of this.statusCallbacks) {
      try { cb(status); } catch (e) { console.error(e); }
    }
  }

  _notifyData(samples, seq) {
    for (const cb of this.dataCallbacks) {
      try { cb(samples, seq); } catch (e) { console.error(e); }
    }
  }

  /**
   * Connects to Pokidex via Web Bluetooth API (Chrome / Edge / Opera)
   * @returns {Promise<boolean>}
   */
  async connect() {
    if (!navigator.bluetooth) {
      throw new Error('Web Bluetooth API is not supported in this browser. Please use Google Chrome or Microsoft Edge.');
    }

    this._notifyStatus('requesting_device');

    this.device = await navigator.bluetooth.requestDevice({
      filters: [{ services: [POKIDEX_SERVICE_UUID] }],
      optionalServices: [POKIDEX_SERVICE_UUID]
    });

    this.device.addEventListener('gattserverdisconnected', () => {
      this.isConnected = false;
      this.characteristic = null;
      this.server = null;
      this._notifyStatus('disconnected');
    });

    this._notifyStatus('connecting_gatt');
    this.server = await this.device.gatt.connect();

    this._notifyStatus('discovering_service');
    const service = await this.server.getPrimaryService(POKIDEX_SERVICE_UUID);
    this.characteristic = await service.getCharacteristic(POKIDEX_CHARACTERISTIC_UUID);

    await this.characteristic.startNotifications();
    this.characteristic.addEventListener('characteristicvaluechanged', (e) => this._onValueChanged(e));

    this.isConnected = true;
    this._notifyStatus('connected');
    return true;
  }

  _onValueChanged(event) {
    const dataView = event.target.value;
    if (dataView.byteLength < 4) return;

    // 1. FAST-PATH: Compact 13-Byte Binary Frame (0xAA 0x01)
    if (dataView.getUint8(0) === 0xAA && dataView.getUint8(1) === 0x01) {
      const seq = (dataView.getUint8(2) << 8) | dataView.getUint8(3);
      const chCount = dataView.getUint8(4);
      const samples = [];
      for (let i = 0; i < chCount; i++) {
        const rawInt16 = dataView.getInt16(5 + (i * 2), false); // Big-endian
        samples.push(rawInt16 / 10.0); // Scaled microvolts
      }
      this._notifyData(samples, seq);
      return;
    }

    // 2. FALLBACK: Chunked JSON Frame
    const seq = (dataView.getUint8(0) << 8) | dataView.getUint8(1);
    const chunkIdx = dataView.getUint8(2);
    const totalChunks = dataView.getUint8(3);
    const chunkBytes = new Uint8Array(dataView.buffer, dataView.byteOffset + 4, dataView.byteLength - 4);

    if (!this.chunkAssembly.has(seq)) {
      this.chunkAssembly.set(seq, new Array(totalChunks));
    }
    const chunks = this.chunkAssembly.get(seq);
    chunks[chunkIdx] = chunkBytes;

    if (chunks.filter(Boolean).length === totalChunks) {
      let totalLen = chunks.reduce((acc, c) => acc + c.length, 0);
      let merged = new Uint8Array(totalLen);
      let offset = 0;
      for (const c of chunks) {
        merged.set(c, offset);
        offset += c.length;
      }
      this.chunkAssembly.delete(seq);

      try {
        const jsonStr = new TextDecoder().decode(merged);
        const frame = JSON.parse(jsonStr);
        if (frame.data && frame.data.channel_samples) {
          this._notifyData(frame.data.channel_samples, frame.data.sequence || seq);
        }
      } catch (err) {
        console.error('JSON chunk parse error:', err);
      }
    }
  }

  /**
   * Sends a two-way UTF-8 command back to the Pokidex phone app
   * @param {string} cmd
   */
  async sendCommand(cmd) {
    if (!this.characteristic || !this.isConnected) {
      throw new Error('Cannot send command: BLE characteristic not connected.');
    }
    const bytes = new TextEncoder().encode(cmd.trim());
    if (this.characteristic.writeValueWithResponse) {
      await this.characteristic.writeValueWithResponse(bytes);
    } else {
      await this.characteristic.writeValue(bytes);
    }
  }

  /**
   * Live-switches the patient preset condition on the active stream
   * @param {string} presetId (e.g. 'p01', 'p02', 'p03', 'p04', 'p05', etc.)
   */
  async setPreset(presetId) {
    await this.sendCommand(`PRESET:${presetId}`);
  }

  /**
   * Sets stream format to 13-byte compact binary
   */
  async setBinaryFormat() {
    await this.sendCommand('FORMAT:BIN');
  }

  /**
   * Sets stream format to JSON
   */
  async setJsonFormat() {
    await this.sendCommand('FORMAT:JSON');
  }

  /**
   * Starts signal stream remotely
   */
  async startStream() {
    await this.sendCommand('START');
  }

  /**
   * Stops signal stream remotely
   */
  async stopStream() {
    await this.sendCommand('STOP');
  }

  /**
   * Disconnects from the BLE peripheral
   */
  disconnect() {
    if (this.device && this.device.gatt.connected) {
      this.device.gatt.disconnect();
    }
    this.isConnected = false;
    this.characteristic = null;
    this.server = null;
    this._notifyStatus('disconnected');
  }
}
