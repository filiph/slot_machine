import 'dart:html';
import 'dart:async';
import 'dart:math';

void main() {
  var slotMachine = new SlotMachineAnimation(0.6, width: 40);
  
  var container = querySelector("#sample_container_id");
  
  container.append(slotMachine.canvasEl);
  container.append(slotMachine.resultEl);
  slotMachine.roll();
}

class SlotMachineAnimation {
  SlotMachineAnimation(this.probability, {this.slots: 5, this.width: 20}) {
    canvasEl = new CanvasElement(width: width * slots, height: width * 3);
    canvasEl.style.border = "1px solid red";
    _ctx = canvasEl.context2D;
    height = width;
    
    resultEl = new SpanElement();
    
    _lines = new List<_SlotMachineLine>(slots);
    for (int i = 0; i < slots; i += 1) {
      _lines[i] = new _SlotMachineLine(probability, _ctx, i * width,
          width, height);
    }
    currentResults = new List<bool>(slots);
    
    if (slots % 2 == 0) {
      throw new ArgumentError("Slots need to be an odd number.");
    }
  }
  final int slots;
  final int width;
  int height;

  final num probability;
  int result;
  
  CanvasElement canvasEl;
  CanvasRenderingContext2D _ctx;
  
  SpanElement resultEl;
  
  List<_SlotMachineLine> _lines;
  
  Completer<int> _rollCompleter;
  
  Future<int> roll() {
    if (_rollCompleter != null) {
      throw new StateError("Cannot roll one slot machine twice.");
    }
    _rollCompleter = new Completer<int>();
    
    update(0);
    
    return _rollCompleter.future;
  }
  
  num last_t = 0;
  List<bool> currentResults;
  
  void update(num dt) {
//    clear();
    
    for (int i = 0; i < slots; i++) {
      _SlotMachineLine line = _lines[i];
      currentResults[i] = line.currentResult;
      if (line.isFinished) continue;
      if (last_t > line.fullSpeedMilliseconds) line.isSlowingDown = true;
      line.update(dt);
    }
    
    resultEl.text = currentResultText;
    
    window.animationFrame.then((num timeFromStart) {
      num dt = timeFromStart - last_t;
      last_t = timeFromStart;
      update(dt);
    });
  }
  
  String get currentResultText {
    if (currentResults.any((result) => result == null)) return "";
    int positives = currentResults
        .fold(0, (int sum, bool result) => sum += result ? 1 : 0);
    int negatives = slots - positives;
    if (positives == slots) return "critical success";
    if (negatives == slots) return "critical fail";
    if (positives > negatives) return "success";
    if (positives < negatives) return "fail";
    // Slots are always odd.
  }
  
  void clear() {
//    _ctx.clearRect(0, 0, width * slots, height * 3);
    _ctx.fillStyle = '#ffffff';
    _ctx.fillRect(0, 0, width * slots, height * 3);
    
//    _ctx.rect(0, 0, width * slots, height * 3);
//    _ctx.fillStyle = 'white';
//    _ctx.fill();
  }
  
  static const int CRITICAL_HIT = 2;
  static const int HIT = 1;
  static const int FAIL = -1;
  static const int CRITICAL_FAIL = -2;
  
  // TODO: completedWithHit, completedWithFail ... getters
  
}

class _SlotMachineLine {
  static const int SLOT_COUNT = 10;
  static final Random _random = new Random();
  
  final num probability;
  final int leftOffset; 
  final int width;
  final int height;
  num fullSpeedMilliseconds;
  final CanvasRenderingContext2D _ctx;
  
  _SlotMachineLine(this.probability, this._ctx, this.leftOffset,
      this.width, this.height) {
    _values = new List<bool>(SLOT_COUNT);
    for (int i = 0; i < SLOT_COUNT; i += 1) {
      _values[i] = _random.nextDouble() < probability;
    }
   
    fullSpeedMilliseconds = _random.nextInt(2000);
  }
  
  num topOffset = 0;
  num speed = 0.01;
  num drag = 0.0001;
  bool isSlowingDown = false;
  bool isFinished = false;
  
  num _pos = 0;
  
  bool currentResult;
  
  List<bool> _values;
  
  void drawSquare(num topOffset, bool value) {
    _ctx.fillStyle = value ? 'green' : 'red';
    //    ctx.setFillColorRgb(255, 0, 0);
    _ctx.fillRect(leftOffset, topOffset, width, height);
  }
  
  void update(num dt) {
    if (isFinished) return;
    
    if (isSlowingDown) {
      if (speed <= 0.001) {
        if ((_pos % height).abs() < height / 20) {
          speed = 0;
          isSlowingDown = false;
          isFinished = true;
        }
      } else {
        speed -= drag;
      }
    }
    
    _pos += (dt * speed * height);
    num normalizedPos = _pos % (height * SLOT_COUNT);
    
    int topIndex = (normalizedPos / height).floor();
    currentResult = _values[(topIndex - 2) % SLOT_COUNT];
    for (int i = 0; i < 3 + 1; i++) {
      int index = topIndex - i; 
      drawSquare((normalizedPos % height) - height + (height * i), 
          _values[index % SLOT_COUNT]);
    }
  }
}
