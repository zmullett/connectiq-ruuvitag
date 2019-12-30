using Toybox.Lang;
using Toybox.Timer;
using Toybox.WatchUi;

class RuuviTagSensorView extends WatchUi.View {

	private var data_ = null;
	private var lastUpdated_ = null;
	private var timer_ = new Timer.Timer();

    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.SensorLayout(dc));
    }

	private function getHumidityLabelText(humidityPercent) {
		return humidityPercent.format("%.1f") + " %";
	}

	private function getTemperatureLabelText(temperatureDegC) {
		return temperatureDegC.format("%.1f") + " °C";
	}
	
	private function getPressureLabelText(pressurePa) {
		return (pressurePa / 100f).format("%.2f") + " hPa";
	}
	
	private function getAccelerationLabelText(accelerationMilliG) {
		return (accelerationMilliG[:x] / 1000f).format("%.1f")
			+ ", " + (accelerationMilliG[:y] / 1000f).format("%.1f")
			+ ", " + (accelerationMilliG[:z] / 1000f).format("%.1f")
			+ " g";
	}
	
	private function getBatteryVoltageLabelText(batteryMilliVolts) {
		return (batteryMilliVolts / 1000f).format("%.1f") + " V";
	}
	
	private function getRssiLabelText(rssiDbm) {
		return rssiDbm.format("%d") + " dBm";
	}
	
	private function getLatencyLabelText() {
		if (lastUpdated_ == null) {
			return "";
		}
		return Time.now().compare(lastUpdated_).format("%d") + " s ago";
	}

    function onUpdate(dc) {
        View.onUpdate(dc);
		View.findDrawableById("humidity").setText(
			getHumidityLabelText(data_[:humidityPercent]));
		View.findDrawableById("temperature").setText(
			getTemperatureLabelText(data_[:temperatureDegC]));
		View.findDrawableById("pressure").setText(
			getPressureLabelText(data_[:pressurePa]));
		View.findDrawableById("acceleration").setText(
			getAccelerationLabelText(data_[:accelerationMilliG]));
		View.findDrawableById("voltage").setText(
			getBatteryVoltageLabelText(data_[:batteryMilliVolts]));
		View.findDrawableById("rssi").setText(
			getRssiLabelText(data_[:rssiDbm]));
		View.findDrawableById("latency").setText(getLatencyLabelText());
		timer_.start(new Lang.Method(WatchUi, :requestUpdate), 100, false);
    }
    
    function onHide() {
    	timer_.stop();
    }
    
	function setData(data) {
		data_ = data;
		lastUpdated_ = Time.now();
	}
}

class RuuviTagSensorBehaviorDelegate extends WatchUi.BehaviorDelegate {

	private var onSensorNextPageCallback_;
	private var onSensorPreviousPageCallback_;

    function initialize(
    		onSensorNextPageCallback, onSensorPreviousPageCallback) {
        BehaviorDelegate.initialize();
        onSensorNextPageCallback_ = onSensorNextPageCallback;
        onSensorPreviousPageCallback_ = onSensorPreviousPageCallback;
    }

    function onNextPage() {
    	return onSensorNextPageCallback_.invoke();
    }

    function onPreviousPage() {
    	return onSensorPreviousPageCallback_.invoke();
    }
}