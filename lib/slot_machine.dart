library slot_machine;

import 'dart:html';
import 'dart:async';
import 'dart:math';

import 'package:slot_machine/precomputed_setups.dart' show getPrecomputedSetup;

/// A class that creates the slot machine. 
/// 
/// It currently only creates slot machines with 5 slot lines, 10 images each.
/// The slot machine is visualized through 2 DOM elements. [canvasEl] shows
/// the slot machine itself, with rotating slots. [resultEl] is a span element
/// that automatically populates with the current outcome in real time.
/// 
/// The SlotMachineAnimation is single-serving, i.e. it cannot be rolled more
/// than once.
class SlotMachineAnimation {
  SlotMachineAnimation(List<num> linesProbabilities) {
    assert(linesProbabilities.length == slotLines);
    height = width;
    
    canvasEl = new CanvasElement(width: width * slotLines, height: width * 3);
    _ctx = canvasEl.context2D;
    resultEl = new SpanElement();
    
    _lines = new List<_SlotMachineLine>(slotLines);
    for (int i = 0; i < slotLines; i += 1) {
      _lines[i] = new _SlotMachineLine(linesProbabilities[i], _ctx, i * width,
          width, height, _successSource, _failureSource);
    }
    currentResults = new List<bool>(slotLines);
    
    if (slotLines % 2 == 0) {
      throw new ArgumentError("Slots need to be an odd number.");
    }
    
    // Prepare gradient
    _gradient = _ctx.createLinearGradient(0, 0, 0, canvasEl.height);
    _gradient.addColorStop(0, 'rgba(255,255,255,1)');
    _gradient.addColorStop(0.1, 'rgba(255,255,255,1)');
    _gradient.addColorStop(0.4, 'rgba(255,255,255,0)');
    _gradient.addColorStop(0.6, 'rgba(255,255,255,0)');
    _gradient.addColorStop(0.9, 'rgba(255,255,255,1)');
    _gradient.addColorStop(1, 'rgba(255,255,255,1)');
  }
  
  factory SlotMachineAnimation.fromProbability(num probability) {
    return new SlotMachineAnimation(getPrecomputedSetup(probability));
  }
  
  final int slotLines = 5;
  final int width = 40;
  int height;

  bool allowCriticalSuccess = true;
  bool allowCriticalFailure = true;
  
  CanvasElement canvasEl;
  CanvasRenderingContext2D _ctx;
  
  CanvasGradient _gradient;
  static const int FADE_IN_MILLISECONDS = 500;
  
  final ImageElement _successSource = 
      new ImageElement(src: "packages/slot_machine/img/slot-success.gif", 
          width: 40, height: 40);
  final ImageElement _failureSource = 
      new ImageElement(src: "packages/slot_machine/img/slot-failure.gif", 
          width: 40, height: 40);
  
  SpanElement resultEl;
  
  List<_SlotMachineLine> _lines;
  
  Completer<String> _rollCompleter;
  
  Future<String> roll() {
    if (_rollCompleter != null) {
      throw new StateError("Cannot roll one slot machine twice.");
    }
    _rollCompleter = new Completer<String>();
    
    Future.wait([_successSource.onLoad.first, _failureSource.onLoad.first])
    .then((_) {
      update(0);
    });
    
    return _rollCompleter.future;
  }
  
  num last_t = 0;
  num _timeOfStartOfRoll;
  List<bool> currentResults;
  
  static const num MAXIMUM_DT = 1000 / 30;
  
  void update(num timeFromStartOfPage) {
    if (_timeOfStartOfRoll == null && timeFromStartOfPage != 0) {
      _timeOfStartOfRoll = timeFromStartOfPage;
    }
    num dt = timeFromStartOfPage - last_t;
    if (dt > MAXIMUM_DT) dt = MAXIMUM_DT;  // Disallow huge dt steps.
    last_t = timeFromStartOfPage;
    
    if (_lines.every((line) => line.isFinished)) {
      resultEl.text = currentResultText;
      _rollCompleter.complete(currentResultText);
      return;
    }
    
    for (int i = 0; i < slotLines; i++) {
      _SlotMachineLine line = _lines[i];
      currentResults[i] = line.currentResult;
      if (_timeOfStartOfRoll != null &&
          last_t - _timeOfStartOfRoll > line.fullSpeedMilliseconds) {
        line.isSlowingDown = true;
      }
      line.update(dt);
    }
    
    // Draw the gradient overlay.
    _ctx.fillStyle = _gradient;
    _ctx.fillRect(0, 0, width * slotLines, height * 3);
    
    // Fade in.
    if (_timeOfStartOfRoll != null && 
        last_t - _timeOfStartOfRoll < FADE_IN_MILLISECONDS) {
      _ctx.fillStyle = "rgba(255, 255, 255, "
          "${1 - (last_t - _timeOfStartOfRoll) / FADE_IN_MILLISECONDS})";
      _ctx.fillRect(0, 0, width * slotLines, height * 3);
    }
    
    resultEl.text = currentResultText;
    
    window.animationFrame.then(update);
  }
  
  static const String CRITICAL_SUCCESS = "critical success";
  static const String SUCCESS = "success";
  static const String FAILURE = "failure";
  static const String CRITICAL_FAILURE = "critical failure";
  
  String get currentResultText {
    if (currentResults.any((result) => result == null)) return "";
    int positives = currentResults
        .fold(0, (int sum, bool result) => sum += result ? 1 : 0);
    int negatives = slotLines - positives;
    if (allowCriticalSuccess && positives == slotLines) return CRITICAL_SUCCESS;
    if (allowCriticalFailure && negatives == slotLines) return CRITICAL_FAILURE;
    if (positives > negatives) return SUCCESS;
    if (positives < negatives) return FAILURE;
    // Slots are always odd.
    throw new StateError("Cannot decide success or fail.");
  }
}

class _SlotMachineLine {
  static const int SLOT_COUNT = 10;
  static const int MIN_FULL_SPEED_MILLISECONDS = 500;
  static final Random _random = new Random();
  
  final num probability;
  final int leftOffset; 
  final int width;
  final int height;
  num fullSpeedMilliseconds;
  final CanvasRenderingContext2D _ctx;
  
  _SlotMachineLine(this.probability, this._ctx, this.leftOffset,
      this.width, this.height, this.successSource, this.failureSource) {
    _values = new List<bool>.filled(SLOT_COUNT, false);
    
    int successValuesTarget = (SLOT_COUNT * probability).round();
    int successValuesCurrent = 0;
    while (successValuesCurrent < successValuesTarget) {
      int index = _random.nextInt(SLOT_COUNT);
      if (_values[index] == false) {
        _values[index] = true;
        successValuesCurrent += 1;
      }
    }
   
    fullSpeedMilliseconds = MIN_FULL_SPEED_MILLISECONDS + _random.nextInt(2000);
    speed += speed * (_random.nextDouble() / 10);
    
    // Fail otherwise, because our assets are 40x40.
    assert(width == 40);
    assert(height == 40);
  }
  
  num topOffset = 0;
  num speed = 0.01;
  num drag = 0.0001;
  bool isSlowingDown = false;
  bool isFinished = false;
  
  final CanvasImageSource successSource;
  final CanvasImageSource failureSource;
  
  num _pos = 0;
  
  bool currentResult;
  
  List<bool> _values;
  
  void drawSquare(num topOffset, bool value) {
//    _ctx.fillStyle = value ? 'green' : 'red';
    //    ctx.setFillColorRgb(255, 0, 0);
//    _ctx.fillRect(leftOffset, topOffset, width, height);
    
    _ctx.drawImage(value ? successSource : failureSource, 
        leftOffset, topOffset);
  }
  
  void update(num dt) {
    if (isSlowingDown && !isFinished) {
      if (speed <= 0.001) {
        if ((_pos % height).abs() < height / 20) {
          speed = 0;
          isFinished = true;
        }
      } else {
        speed -= drag;
      }
    }
    
    clear();
    
    if (!isFinished) {
      _pos += (dt * speed * height);
    }
    num normalizedPos = _pos % (height * SLOT_COUNT);
    
    int topIndex = (normalizedPos / height).floor();
    currentResult = _values[(topIndex - 2) % SLOT_COUNT];
    for (int i = 0; i < 3 + 1; i++) {
      int index = topIndex - i; 
      drawSquare((normalizedPos % height) - height + (height * i), 
          _values[index % SLOT_COUNT]);
    }
    
  }
  
  void clear() {
    _ctx.fillStyle = '#ffffff';
    _ctx.fillRect(leftOffset, 0, width, height * 3);
  }
}
