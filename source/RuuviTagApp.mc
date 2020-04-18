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
		sensorViews_[addressIndexMap_[address]].setContent(data, sensorViews_.size() > 1);
		WatchUi.requestUpdate();
		if (firstSensor) {
			onSummarySelect();
		}
	}
}