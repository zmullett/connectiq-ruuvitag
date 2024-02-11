import Toybox.Lang;
import Toybox.WatchUi;

class RuuviTagSensorView extends WatchUi.View {

  private var labelSecondsAgo = WatchUi.loadResource(Rez.Strings.SecondsAgo);

  private var data_ as Dictionary<Symbol, Number> or Null = null;
  private var sensorAliases_ = null;
  private var showNextPageArrow_ = false;
  private var lastUpdated_ = null;

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
    return Time.now().compare(lastUpdated_).format("%d") + " " + labelSecondsAgo;
  }

  private function drawNextPageArrow(dc) {
    var xCenter = dc.getWidth() / 2;
    var yBottom = dc.getHeight();
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
    dc.fillPolygon([
      [xCenter - 7, yBottom - 8],
      [xCenter, yBottom - 1],
      [xCenter + 7,  yBottom - 8]
    ]);
  }

  private function getSensorDisplayName(macAddress) {
    return (sensorAliases_[macAddress]) ? sensorAliases_[macAddress] : macAddress;
  }

  function onUpdate(dc) {
    View.onUpdate(dc);

    if (data_.hasKey(:macAddress)) {
      var addressView = View.findDrawableById("address") as WatchUi.Text;
      addressView.setText(getSensorDisplayName(data_[:macAddress]));
    }

    var humidityView = View.findDrawableById("humidity") as WatchUi.Text;
    humidityView.setText(getHumidityLabelText(data_[:humidityPercent]));

    var temperatureView = View.findDrawableById("temperature") as WatchUi.Text;
    temperatureView.setText(getTemperatureLabelText(data_[:temperatureDegC]));

    var pressureView = View.findDrawableById("pressure") as WatchUi.Text;
    pressureView.setText(getPressureLabelText(data_[:pressurePa]));

    var accelerationView = View.findDrawableById("acceleration") as WatchUi.Text;
    accelerationView.setText(getAccelerationLabelText(data_[:accelerationMilliG]));

    var voltageView = View.findDrawableById("voltage") as WatchUi.Text;
    voltageView.setText(getBatteryVoltageLabelText(data_[:batteryMilliVolts]));

    var rssiView = View.findDrawableById("rssi") as WatchUi.Text;
    rssiView.setText(getRssiLabelText(data_[:rssiDbm]));

    var latencyView = View.findDrawableById("latency") as WatchUi.Text;
    latencyView.setText(getLatencyLabelText());

    if (showNextPageArrow_) {
      drawNextPageArrow(dc);
    }
  }

  function setContent(data, sensorAliases, showNextPageArrow) {
    data_ = data;
    sensorAliases_ = sensorAliases;
    showNextPageArrow_ = showNextPageArrow;
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