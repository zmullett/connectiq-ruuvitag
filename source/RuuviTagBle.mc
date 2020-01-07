using Toybox.BluetoothLowEnergy;
using Toybox.Math;
using Toybox.Timer;

// https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
const RUUVI_INNOVATIONS_COMPANY_ID = 0x0499;

function decodeTwosComplement(raw, numBits) {
	var mask = 1 << (numBits - 1);
	return -(raw & mask) + (raw & ~mask);    	    	
	}
	
function formatMacAddress(bytes) {
	var address = "";
	for (var i = 0; i < bytes.size(); i++) {
		if (address.length() > 0) {
			address += ":";
		}
		address += bytes[i].format("%X");
	}
	return address;
}

// https://github.com/ruuvi/ruuvi-sensor-protocols/blob/master/dataformat_03.md
function interpretRuuviDataFormat3(data) {
	if (data.size() != 14) {
		return null;
	}
	return {
		:humidityPercent => data[1] / 2f,
		:temperatureDegC => data[2] + data[3] / 100f,
		:pressurePa => (data[4] << 8) + data[5] + 50000,
		:accelerationMilliG => {
			:x => decodeTwosComplement((data[6] << 8) + data[7], 16),
			:y => decodeTwosComplement((data[8] << 8) + data[9], 16),
			:z => decodeTwosComplement((data[10] << 8) + data[11], 16),
		},
		:batteryMilliVolts => (data[12] << 8) + data[13]
	};
}

(:test) function interpretRuuviDataFormat3Test(logger) {
	var result = interpretRuuviDataFormat3([
		0x03, 0x29, 0x1A, 0x1E, 0xCE, 0x1E, 0xFC, 0x18,
		0xF9, 0x42, 0x02, 0xCA, 0x0B, 0x53
	]);
	logger.debug(result);
	return Math.round(result[:temperatureDegC] * 10) == 263
		&& result[:pressurePa] == 102766
		&& Math.round(result[:humidityPercent] * 10) == 205
		&& result[:accelerationMilliG][:x] == -1000
		&& result[:accelerationMilliG][:y] == -1726
		&& result[:accelerationMilliG][:z] == 714
		&& result[:batteryMilliVolts] == 2899;
}

// https://github.com/ruuvi/ruuvi-sensor-protocols/blob/master/dataformat_05.md
function interpretRuuviDataFormat5(data) {
	if (data.size() != 24) {
		return null;
	}
	var powerInfo = (data[13] << 8) + data[14];
	return {
		:temperatureDegC => decodeTwosComplement(
			(data[1] << 8) + data[2], 16) * 0.005f,
		:humidityPercent => ((data[3] << 8) + data[4]) * 0.0025f,
		:pressurePa => (data[5] << 8) + data[6] + 50000,
		:accelerationMilliG => {
			:x => decodeTwosComplement((data[7] << 8) + data[8], 16),
			:y => decodeTwosComplement((data[9] << 8) + data[10], 16),
			:z => decodeTwosComplement((data[11] << 8) + data[12], 16),
		},
		:batteryMilliVolts => powerInfo >> 5 + 1600,
		:transmitPowerDbm => (powerInfo & 0x1F) * 2 - 40,
		:movementCounter => data[15],
		:measurementSequenceNumber => (data[16] << 8) + data[17],
		:macAddress => formatMacAddress(data.slice(18, 24)),
	};
}

(:test) function interpretRuuviDataFormat5Test(logger) {
	var result = interpretRuuviDataFormat5([
		0x05, 0x12, 0xFC, 0x53, 0x94, 0xC3, 0x7C, 0x00,
		0x04, 0xFF, 0xFC, 0x04, 0x0C, 0xAC, 0x36, 0x42,
		0x00, 0xCD, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
	]);
	logger.debug(result);
	return Math.round(result[:temperatureDegC] * 10) == 243
		&& result[:pressurePa] == 100044
		&& Math.round(result[:humidityPercent] * 100) == 5349
		&& result[:accelerationMilliG][:x] == 4
		&& result[:accelerationMilliG][:y] == -4
		&& result[:accelerationMilliG][:z] == 1036
		&& result[:batteryMilliVolts] == 2977
		&& result[:transmitPowerDbm] == 4
		&& result[:movementCounter] == 66
		&& result[:measurementSequenceNumber] == 205
		&& result[:macAddress].equals("CB:B8:33:4C:88:4F");
}

class RuuviTagBleDelegate extends BluetoothLowEnergy.BleDelegate {

	private var callback_;
	private var comparableScanResults_;

	function initialize(callback) {
		BleDelegate.initialize();
		BluetoothLowEnergy.setDelegate(self);
		callback_ = callback;
		comparableScanResults_ = [];
	}
	
	function startScanning() {
		BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
	}

	// Ble.BleDelegate override
    function onScanResults(iterator) {
        for (var sr = iterator.next(); sr != null; sr = iterator.next()) {
			processScanResult(sr);
    	}
    }
    
    private function processScanResult(scanResult) {
		var data = interpretRuuviData(
			scanResult.getManufacturerSpecificData(RUUVI_INNOVATIONS_COMPANY_ID));
		if (data == null) {
			return;
		}
		data[:rssiDbm] = scanResult.getRssi();
		callback_.invoke(getAddress(scanResult).format("%d"), data);
    }
    
    private function getAddress(scanResult) {
    	for (var i=0; i < comparableScanResults_.size(); i++) {
    		if (scanResult.isSameDevice(comparableScanResults_[i])) {
    			return i;
    		}
    	}
    	comparableScanResults_.add(scanResult);
    	return comparableScanResults_.size() - 1;
    }
    
	private function interpretRuuviData(data) {
		if (data != null && data.size() > 0) {
			if (data[0] == 3) {
				return interpretRuuviDataFormat3(data);
			}
			if (data[0] == 5) {
				return interpretRuuviDataFormat5(data);
			}
		}
		return null;
	}
}

(:debug) class FakeRuuviTagBleDelegate {

	private var callback_;
	private var timers_;
	private var measurementSequenceNumber_ = 0;

	function initialize(callback) {
		callback_ = callback;
		timers_ = [
			createInterval(:notifyTag1, 1000),
			createInterval(:notifyTag2, 2100)
		];
	}
	
	private function createInterval(methodLabel, periodMs) {
		var timer = new Timer.Timer();
		timer.start(method(methodLabel), periodMs, true);
		return timer;	
	}

	function notifyTag1() {
		callback_.invoke("fake1", {
			:rssiDbm => Math.rand() % 10 - 90,
			:humidityPercent => (Math.rand() % 20) / 10f + 60f,
			:temperatureDegC => (Math.rand() % 50) / 10f + 10f,
			:pressurePa => -(Math.rand() % 1000) + 100000,
			:accelerationMilliG => {
				:x => 0,
				:y => 0,
				:z => 1000,
			},
			:batteryMilliVolts => 2100
		});
	}
	
	function notifyTag2() {
		measurementSequenceNumber_++;
		callback_.invoke("fake2", {
			:rssiDbm => Math.rand() % 10 - 80,
			:humidityPercent => (Math.rand() % 20) / 10f + 40f,
			:temperatureDegC => (Math.rand() % 50) / 10f + 20f,
			:pressurePa => -(Math.rand() % 1000) + 90000,
			:accelerationMilliG => {
				:x => 707,
				:y => -707,
				:z => 0,
			},
			:batteryMilliVolts => 1900,
			:transmitPowerDbm => 4,
			:movementCounter => 1,
			:measurementSequenceNumber => measurementSequenceNumber_,
			:macAddress => "01:02:03:04:05",
		});
	}
}