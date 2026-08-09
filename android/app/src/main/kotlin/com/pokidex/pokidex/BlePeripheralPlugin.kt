package com.pokidex.pokidex

import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

@SuppressLint("MissingPermission")
class BlePeripheralPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var bluetoothGattServer: BluetoothGattServer? = null
    private var gattCharacteristic: BluetoothGattCharacteristic? = null

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val connectedDevices = mutableSetOf<BluetoothDevice>()
    private var isAdvertising = false
    private var currentMtu = 23 // Default BLE MTU

    companion object {
        val SERVICE_UUID: UUID = UUID.fromString("0000fe50-0000-1000-8000-00805f9b34fb")
        val CHARACTERISTIC_UUID: UUID = UUID.fromString("0000fe51-0000-1000-8000-00805f9b34fb")
        val CLIENT_CONFIG_DESCRIPTOR_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.pokidex.pokidex/ble")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.pokidex.pokidex/ble_events")
        eventChannel.setStreamHandler(this)

        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopAdvertisingInternal()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startAdvertising" -> {
                val deviceName = call.argument<String>("deviceName") ?: "Pokidex-EEG"
                startAdvertisingInternal(deviceName, result)
            }
            "stopAdvertising" -> {
                stopAdvertisingInternal()
                result.success(true)
            }
            "sendChunk" -> {
                val bytes = call.argument<ByteArray>("data")
                if (bytes != null) {
                    sendChunkInternal(bytes, result)
                } else {
                    result.error("INVALID_ARG", "Data bytes null", null)
                }
            }
            "getStatus" -> {
                val map = mapOf(
                    "isAdvertising" to isAdvertising,
                    "connectedCount" to connectedDevices.size,
                    "connectedDevices" to connectedDevices.map { it.name ?: it.address },
                    "mtu" to currentMtu
                )
                result.success(map)
            }
            else -> result.notImplemented()
        }
    }

    private fun startAdvertisingInternal(deviceName: String, result: MethodChannel.Result) {
        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            result.error("BT_DISABLED", "Bluetooth adapter is disabled or null", null)
            return
        }

        bluetoothLeAdvertiser = bluetoothAdapter!!.bluetoothLeAdvertiser
        if (bluetoothLeAdvertiser == null) {
            result.error("NO_ADVERTISER", "BLE Advertising not supported on this device", null)
            return
        }

        try {
            bluetoothAdapter!!.name = deviceName
        } catch (_: Exception) {}

        // Setup GATT Server
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothGattServer = bluetoothManager.openGattServer(context, gattServerCallback)

        if (bluetoothGattServer == null) {
            result.error("GATT_ERROR", "Could not open GATT Server", null)
            return
        }

        // Setup GATT Service & Characteristic
        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        gattCharacteristic = BluetoothGattCharacteristic(
            CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY or BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_READ
        )

        val descriptor = BluetoothGattDescriptor(
            CLIENT_CONFIG_DESCRIPTOR_UUID,
            BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
        )
        gattCharacteristic!!.addDescriptor(descriptor)
        service.addCharacteristic(gattCharacteristic)

        bluetoothGattServer!!.addService(service)

        // Setup Advertise Settings & Data
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        bluetoothLeAdvertiser!!.startAdvertising(settings, data, advertiseCallback)
        isAdvertising = true
        emitLog("BLE Advertising started as '$deviceName' (Service: 0000fe50)")
        result.success(true)
    }

    private fun stopAdvertisingInternal() {
        try {
            bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        } catch (_: Exception) {}
        try {
            bluetoothGattServer?.close()
        } catch (_: Exception) {}

        bluetoothLeAdvertiser = null
        bluetoothGattServer = null
        isAdvertising = false
        connectedDevices.clear()
        emitLog("BLE Advertising stopped")
    }

    private fun sendChunkInternal(data: ByteArray, result: MethodChannel.Result) {
        if (gattCharacteristic == null || bluetoothGattServer == null || connectedDevices.isEmpty()) {
            result.success(false)
            return
        }

        gattCharacteristic!!.value = data
        var sentAny = false
        for (device in connectedDevices) {
            val ok = bluetoothGattServer!!.notifyCharacteristicChanged(device, gattCharacteristic, false)
            if (ok) sentAny = true
        }
        result.success(sentAny)
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            isAdvertising = true
            emitLog("BLE Peripheral advertising success")
        }

        override fun onStartFailure(errorCode: Int) {
            isAdvertising = false
            emitLog("BLE Peripheral advertising failed (code $errorCode)")
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                connectedDevices.add(device)
                emitLog("BLE Central connected: ${device.name ?: device.address} (${connectedDevices.size} total)")
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                connectedDevices.remove(device)
                emitLog("BLE Central disconnected: ${device.name ?: device.address} (${connectedDevices.size} remaining)")
            }
        }

        override fun onMtuChanged(device: BluetoothDevice, mtu: Int) {
            currentMtu = mtu
            emitLog("BLE MTU updated to $mtu bytes for ${device.name ?: device.address}")
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            if (characteristic.uuid == CHARACTERISTIC_UUID) {
                bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, characteristic.value)
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            if (descriptor.uuid == CLIENT_CONFIG_DESCRIPTOR_UUID) {
                if (responseNeeded) {
                    bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                }
                emitLog("BLE Central enabled notifications")
            }
        }
    }

    private fun emitLog(msg: String) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to "log", "message" to msg, "timestamp" to System.currentTimeMillis()))
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}