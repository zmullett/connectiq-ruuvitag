using Toybox.WatchUi;

class RuuviTagSummaryView extends WatchUi.View {

	private var sensorCount_ = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.SummaryLayout(dc));
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
        View.findDrawableById("sensorCount").setText(sensorCount_ + " found");
    }
    
    function setSensorCount(sensorCount) {
    	sensorCount_ = sensorCount;
    }
}

class RuuviTagSummaryBehaviorDelegate extends WatchUi.BehaviorDelegate {

	private var onSummarySelectCallback_;

    function initialize(onSummarySelectCallback) {
        BehaviorDelegate.initialize();
        onSummarySelectCallback_ = onSummarySelectCallback;
    }

	function onSelect() {
		return onSummarySelectCallback_.invoke();
	}
}