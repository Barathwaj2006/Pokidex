package com.pokidex.pokidex

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.UUID
import java.util.concurrent.CopyOnWriteArraySet

@SuppressLint("MissingPermission")
class BlePeripheralPlugin(private var activityOverride: Activity? = null) :
    FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler,
    ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var activity: Activity? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val REQUEST_CODE_BT = 9871

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var bluetoothGattServer: BluetoothGattServer? = null
    private var gattCharacteristic: BluetoothGattCharacteristic? = null

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Thread-safe set for concurrent Bluetooth GATT callback and MainThread iterations
    private val connectedDevices = CopyOnWriteArraySet<BluetoothDevice>()
    private var isAdvertising = false
    private var currentMtu = 23 // Default BLE MTU

    companion object {
        val SERVICE_UUID: UUID = UUID.fromString("0000fe50-0000-1000-8000-00805f9b34fb")
        val CHARACTERISTIC_UUID: UUID = UUID.fromString("0000fe51-0000-1000-8000-00805f9b34fb")
        val CLIENT_CONFIG_DESCRIPTOR_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    private fun getForegroundActivity(): Activity? = activity ?: activityOverride

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

    // ActivityAware Lifecycle
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun getRequiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                android.Manifest.permission.BLUETOOTH_ADVERTISE,
                android.Manifest.permission.BLUETOOTH_CONNECT
            )
        } else {
            arrayOf(
                android.Manifest.permission.BLUETOOTH,
                android.Manifest.permission.BLUETOOTH_ADMIN,
                android.Manifest.permission.ACCESS_FINE_LOCATION,
                android.Manifest.permission.ACCESS_COARSE_LOCATION
            )
        }
    }

    private fun hasPermissions(): Boolean {
        for (perm in getRequiredPermissions()) {
            if (ContextCompat.checkSelfPermission(context, perm) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == REQUEST_CODE_BT) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            emitLog(if (allGranted) "Bluetooth permissions granted" else "Bluetooth permissions denied")
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermissions" -> {
                result.success(hasPermissions())
            }
            "requestPermissions" -> {
                if (hasPermissions()) {
                    result.success(true)
                    return
                }
                val act = getForegroundActivity()
                if (act == null) {
                    result.error("NO_ACTIVITY", "Cannot request permissions without foreground Activity", null)
                    return
                }
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(act, getRequiredPermissions(), REQUEST_CODE_BT)
            }
            "isBluetoothEnabled" -> {
                result.success(bluetoothAdapter?.isEnabled == true)
            }
            "startAdvertising" -> {
                val deviceName = call.argument<String>("deviceName") ?: "Pokidex-EEG"
                if (!hasPermissions()) {
                    val act = getForegroundActivity()
                    if (act != null) {
                        emitLog("Requesting Bluetooth permissions before advertising...")
                        pendingPermissionResult = object : MethodChannel.Result {
                            override fun success(res: Any?) {
                                if (res == true) {
                                    startAdvertisingInternal(deviceName, result)
                                } else {
                                    result.error("PERMISSION_DENIED", "Bluetooth permissions were not granted", null)
                                }
                            }
                            override fun error(code: String, msg: String?, details: Any?) {
                                result.error(code, msg, details)
                            }
                            override fun notImplemented() {
                                result.notImplemented()
                            }
                        }
                        ActivityCompat.requestPermissions(act, getRequiredPermissions(), REQUEST_CODE_BT)
                        return
                    } else {
                        result.error("PERMISSION_DENIED", "Bluetooth permissions missing and foreground Activity unavailable", null)
                        return
                    }
                }
                startAdvertisingInternal(deviceName, result)
            }
            "stopAdvertising" -> {
                stopAdvertisingInternal()
                result.success(true)
            }
            "sendChunk", "sendBinary" -> {
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
            "startForegroundService" -> {
                try {
                    TelemetryForegroundService.startService(context)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SERVICE_ERROR", e.message, null)
                }
            }
            "stopForegroundService" -> {
                try {
                    TelemetryForegroundService.stopService(context)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SERVICE_ERROR", e.message, null)
                }
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

        // Launch Foreground Service for zero-drop persistent streaming
        try {
            TelemetryForegroundService.startService(context)
        } catch (_: Exception) {}

        // Setup GATT Server
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothGattServer = bluetoothManager.openGattServer(context, gattServerCallback)

        if (bluetoothGattServer == null) {
            result.error("GATT_ERROR", "Could not open GATT Server", null)
            return
        }

        // Setup GATT Service & Characteristic with Notify, Read, and Write for two-way control
        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        gattCharacteristic = BluetoothGattCharacteristic(
            CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY or
                BluetoothGattCharacteristic.PROPERTY_READ or
                BluetoothGattCharacteristic.PROPERTY_WRITE or
                BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
            BluetoothGattCharacteristic.PERMISSION_READ or
                BluetoothGattCharacteristic.PERMISSION_WRITE
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

        // 31-BYTE FIX: Primary advertisement contains ONLY the 128-bit Service UUID (18 bytes <= 31 bytes)
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        // ScanResponse carries the human-readable device name (avoids ADVERTISE_FAILED_DATA_TOO_LARGE)
        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .build()

        bluetoothLeAdvertiser!!.startAdvertising(settings, data, scanResponse, advertiseCallback)
        isAdvertising = true
        emitLog("BLE Advertising active as '$deviceName' (GATT Service: 0000fe50, Two-Way Read/Write/Notify)")
        emitConnectionState()
        result.success(true)
    }

    private fun stopAdvertisingInternal() {
        try {
            bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        } catch (_: Exception) {}
        try {
            bluetoothGattServer?.close()
        } catch (_: Exception) {}
        try {
            TelemetryForegroundService.stopService(context)
        } catch (_: Exception) {}

        bluetoothLeAdvertiser = null
        bluetoothGattServer = null
        isAdvertising = false
        connectedDevices.clear()
        emitLog("BLE Advertising stopped")
        emitConnectionState()
    }

    private fun sendChunkInternal(data: ByteArray, result: MethodChannel.Result) {
        if (gattCharacteristic == null || bluetoothGattServer == null || connectedDevices.isEmpty()) {
            result.success(false)
            return
        }

        var sentAny = false
        for (device in connectedDevices) {
            val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val statusCode = bluetoothGattServer!!.notifyCharacteristicChanged(
                    device,
                    gattCharacteristic!!,
                    false,
                    data
                )
                statusCode == BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                gattCharacteristic!!.value = data
                @Suppress("DEPRECATION")
                bluetoothGattServer!!.notifyCharacteristicChanged(device, gattCharacteristic!!, false)
            }
            if (ok) sentAny = true
        }
        result.success(sentAny)
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            isAdvertising = true
            emitLog("BLE Peripheral advertising broadcast confirmed active")
            emitConnectionState()
        }

        override fun onStartFailure(errorCode: Int) {
            isAdvertising = false
            emitLog("BLE Peripheral advertising failed (code $errorCode)")
            emitConnectionState()
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                connectedDevices.add(device)
                emitLog("BLE Web/Central device connected: ${device.name ?: device.address} (${connectedDevices.size} total)")
                emitConnectionState()
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                connectedDevices.remove(device)
                emitLog("BLE Web/Central device disconnected: ${device.name ?: device.address} (${connectedDevices.size} remaining)")
                emitConnectionState()
            }
        }

        override fun onMtuChanged(device: BluetoothDevice, mtu: Int) {
            currentMtu = mtu
            emitLog("BLE MTU updated to $mtu bytes for ${device.name ?: device.address}")
            emitConnectionState()
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            if (characteristic.uuid == CHARACTERISTIC_UUID) {
                bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, characteristic.value)
            } else {
                bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            if (characteristic.uuid == CHARACTERISTIC_UUID) {
                val commandStr = String(value, Charsets.UTF_8)
                emitCommand(commandStr, device.name ?: device.address)
                if (responseNeeded) {
                    bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                }
            } else {
                if (responseNeeded) {
                    bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
                }
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
                descriptor.value = value
                connectedDevices.add(device)
                if (responseNeeded) {
                    bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                }
                emitLog("BLE Web/Central enabled characteristic notifications")
                emitConnectionState()
            } else {
                if (responseNeeded) {
                    bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
                }
            }
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            // Hardware-level packet delivery confirmation
        }
    }

    private fun emitLog(msg: String) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to "log", "message" to msg, "timestamp" to System.currentTimeMillis()))
        }
    }

    private fun emitCommand(cmd: String, sender: String) {
        mainHandler.post {
            eventSink?.success(mapOf(
                "type" to "command",
                "command" to cmd,
                "sender" to sender,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    private fun emitConnectionState() {
        mainHandler.post {
            eventSink?.success(mapOf(
                "type" to "connection",
                "isAdvertising" to isAdvertising,
                "connectedCount" to connectedDevices.size,
                "connectedDevices" to connectedDevices.map { it.name ?: it.address },
                "mtu" to currentMtu,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}