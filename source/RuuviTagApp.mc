using Toybox.Application;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.WatchUi;

class RuuviTagApp extends Application.AppBase {
  // Declare, but do not initialize anything here, to prevent errors when in
  // glance mode.
  private var addressIndexMap_;
  private var index_ = 0;
  private var sensorViews_;
  private var summaryView_;
  private var refreshTimer_;
  private var bleDelegate_;
  private var sensorAliases_ = {};

  function initialize() {
    AppBase.initialize();
  }

  (:debug)
  private function createBleDelegate() {
    bleDelegate_ = new FakeRuuviTagBleDelegate(method(:onRuuviTagData));
  }

  (:release)
  private function createBleDelegate() {
    bleDelegate_ = new RuuviTagBleDelegate(method(:onRuuviTagData));
  }

  private function readProperties() {
    for (var i = 0; i < 5; i++) {
      var sensorIndex = i + 1;
      var sensor = "sensor-" + sensorIndex.format("%02d");
      var sensorMacAddress;
      var sensorAlias;

      try {
        sensorMacAddress = Application.Properties.getValue(sensor + "-mac-address");
        sensorAlias = Application.Properties.getValue(sensor + "-alias");

        if (sensorMacAddress.length() > 0 && sensorAlias.length() > 0) {
          sensorAliases_[sensorMacAddress.toUpper()] = sensorAlias;
        }
      }
      catch(ex) {
        /* When Application.Properties.getValue() throws an exception, the
         * widget will work - just without displaying sensor aliases. Handle
         * such exceptions as a warning and not as an error and, thus don't
         * crash the widget.
         */
      }
    }
  }

  function onStart(state) {
    readProperties();
  }

  function getInitialView() {
    addressIndexMap_ = {};
    sensorViews_ = [];
    summaryView_ = new RuuviTagSummaryView();
    refreshTimer_ = new Timer.Timer();
    refreshTimer_.start(
      new Lang.Method(WatchUi, :requestUpdate), 250, true);
    createBleDelegate();

    return [
      summaryView_,
      new RuuviTagSummaryBehaviorDelegate(method(:onSummarySelect))
    ];
  }

  private function createSensorBehaviorDelegate() {
    return new RuuviTagSensorBehaviorDelegate(
      method(:onSensorNextPage),
      method(:onSensorPreviousPage)
    );
  }

  function onSummarySelect() {
    if (sensorViews_.size() == 0) {
      return false;
    }
    WatchUi.pushView(
      sensorViews_[index_],
      createSensorBehaviorDelegate(),
      WatchUi.SLIDE_LEFT
    );
    return true;
  }

  function onSensorNextPage() {
    if (sensorViews_.size() < 2) {
      return false;
    }
    index_ = (index_ + 1) % sensorViews_.size();
    WatchUi.switchToView(
      sensorViews_[index_],
      createSensorBehaviorDelegate(),
      WatchUi.SLIDE_UP
    );
    return true;
  }

  function onSensorPreviousPage() {
    if (sensorViews_.size() < 2) {
      return false;
    }
    index_--;
    if (index_ < 0) {
      index_ = sensorViews_.size() - 1;
    }
    WatchUi.switchToView(
      sensorViews_[index_],
      createSensorBehaviorDelegate(),
      WatchUi.SLIDE_DOWN
    );
    return true;
  }

  function onRuuviTagData(address, data) {
    var firstSensor = sensorViews_.size() == 0;
    if (!addressIndexMap_.hasKey(address)) {
      sensorViews_.add(new RuuviTagSensorView());
      addressIndexMap_[address] = sensorViews_.size() - 1;
      summaryView_.setContent(sensorViews_.size());
    }
    sensorViews_[addressIndexMap_[address]].setContent(
      data, sensorAliases_, sensorViews_.size() > 1);
    WatchUi.requestUpdate();
    if (firstSensor) {
      onSummarySelect();
    }
  }
}