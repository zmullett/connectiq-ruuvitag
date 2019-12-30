using Toybox.Application;
using Toybox.WatchUi;

class RuuviTagApp extends Application.AppBase {
	private var addressIndexMap_ = {};
	private var index_ = 0;
	private var sensorViews_ = [];
	private var summaryView_ = new RuuviTagSummaryView(); 

	// Signal sources.
	private var bleDelegate_ =
		new RuuviTagBleDelegate(method(:onRuuviTagData));
	(:debug) private var fakeBleDelegate_ =
		new FakeRuuviTagBleDelegate(method(:onRuuviTagData));

    function initialize() {
        AppBase.initialize();
    }

	function onStart(state) {
		bleDelegate_.startScanning();
    }

    function getInitialView() {
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
		if (!addressIndexMap_.hasKey(address)) {
			sensorViews_.add(new RuuviTagSensorView());
			addressIndexMap_[address] = sensorViews_.size() - 1;
			summaryView_.setSensorCount(sensorViews_.size());
		}
		sensorViews_[addressIndexMap_[address]].setData(data);
		WatchUi.requestUpdate();
	}
}