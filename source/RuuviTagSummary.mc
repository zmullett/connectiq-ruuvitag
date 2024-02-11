using Toybox.WatchUi;

class RuuviTagSummaryView extends WatchUi.View {

  private var labelFound = WatchUi.loadResource(Rez.Strings.Found);
  private var sensorCount_ = 0;

  function initialize() {
    View.initialize();
  }

  function onLayout(dc) {
    setLayout(Rez.Layouts.SummaryLayout(dc));
  }

  function onUpdate(dc) {
    View.onUpdate(dc);
    var sensorCountView = View.findDrawableById("sensorCount") as WatchUi.Text;
    sensorCountView.setText(sensorCount_ + " " + labelFound);
  }

  function setContent(sensorCount) {
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