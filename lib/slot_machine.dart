library slot_machine;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:slot_machine/precomputed_setups.dart' show getPrecomputedSetup;

part 'src/slot_machine_line.dart';

/// The result of a roll.
enum Result {
  /// Normal success.
  success,

  /// Normal failure.
  failure,

  /// Major success.
  criticalSuccess,

  /// Major failure.
  criticalFailure
}

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
  static const int _fadeInMilliseconds = 500;

  /// The maximum dt that the update method allows.
  ///
  /// Defaults to 30 fps (1000 / 30 = 33ms).
  static final int _maximumDt = 33;

  static const String _criticalSuccessMsg = "critical success";

  static const String _successMsg = "success";

  static const String _failureMsg = "failure";

  static const String _criticalFailureMsg = "critical failure";

  static final Random _random = new Random();

  /// The number of lines (symbols) per each slot.
  final int slotLines = 5;

  /// The width of each slot in pixels.
  final int width = 40;

  /// The height of each slot line (symbol).
  int _height;

  /// Whether or not to allow this slot machine to return critical successes.
  final bool allowCriticalSuccess;

  /// Whether or not to allow this slot machine to return critical failures.
  final bool allowCriticalFailure;

  /// The canvas element that this library creates and that should be added
  /// to the DOM by the library's user.
  CanvasElement canvasEl;

  CanvasRenderingContext2D _ctx;

  CanvasGradient _gradient;

  final ImageElement _successIcon = new ImageElement(
      src: "packages/slot_machine/img/slot-success.gif", width: 40, height: 40);

  final ImageElement _failureIcon = new ImageElement(
      src: "packages/slot_machine/img/slot-failure.gif", width: 40, height: 40);

  /// The result element that this library updates with current result (i.e.
  /// what the slot machine would output if it was immediately halted, frozen
  /// in current state).
  ///
  /// The library's users should add this element to the DOM if the want to
  /// show it.
  SpanElement resultEl;

  List<_SlotMachineLine> _lines;

  Completer<String> _rollCompleter;

  num _lastTime = 0;

  num _timeOfStartOfRoll;

  /// A list of booleans evaluating the slots from left to right.
  List<bool> _currentResults;

  /// Create a slot machine animation with probability of success (of the whole
  /// machine) being [probability].
  factory SlotMachineAnimation.fromProbability(num probability,
      {Result predeterminedResult}) {
    assert(probability > 0 || predeterminedResult != Result.success);
    assert(probability < 1 || predeterminedResult != Result.failure);
    final setup = getPrecomputedSetup(probability);
    return new SlotMachineAnimation._(setup,
        predeterminedResult: predeterminedResult);
  }

  /// Create a [SlotMachineAnimation] by giving probability of success per
  /// each slot with [linesSuccessSymbols].
  ///
  /// Indicate what kinds of results to allow with [allowCriticalSuccess]
  /// and [allowCriticalFailure].
  SlotMachineAnimation._(List<int> linesSuccessSymbols,
      {this.allowCriticalSuccess: false,
      this.allowCriticalFailure: false,
      Result predeterminedResult}) {
    assert(linesSuccessSymbols.length == slotLines);

    _height = width;

    canvasEl = new CanvasElement(width: width * slotLines, height: width * 3);
    _ctx = canvasEl.context2D;
    resultEl = new SpanElement();

    final predeterminedValues = _fillPredeterminedValues(predeterminedResult);

    _lines = new List<_SlotMachineLine>(slotLines);
    for (int i = 0; i < slotLines; i += 1) {
      _lines[i] = new _SlotMachineLine(linesSuccessSymbols[i], _ctx, i * width,
          width, _height, _successIcon, _failureIcon, _random,
          predeterminedResult: predeterminedValues[i]);
    }
    _currentResults = new List<bool>(slotLines);

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

  String get _currentResultText {
    if (_currentResults.any((result) => result == null)) return "";
    final positives = _currentResults.fold(
        0, (int sum, bool result) => sum += result ? 1 : 0);
    final negatives = slotLines - positives;
    if (allowCriticalSuccess && positives == slotLines)
      return _criticalSuccessMsg;
    if (allowCriticalFailure && negatives == slotLines)
      return _criticalFailureMsg;
    if (positives > negatives) return _successMsg;
    if (positives < negatives) return _failureMsg;
    // Slots are always odd.
    throw new StateError("Cannot decide success or fail.");
  }

  /// Start rolling the slot machine. Returns with the text of the result.
  Future<String> roll() {
    if (_rollCompleter != null) {
      throw new StateError("Cannot roll one slot machine twice.");
    }
    _rollCompleter = new Completer<String>();

    Future
        .wait([_successIcon.onLoad.first, _failureIcon.onLoad.first]).then((_) {
      _update(0);
    });

    return _rollCompleter.future;
  }

  List<bool> _fillPredeterminedValues(Result predeterminedResult) {
    if (predeterminedResult == null) {
      return new List<bool>.filled(slotLines, null, growable: false);
    }

    if (predeterminedResult == Result.criticalSuccess) {
      if (!allowCriticalSuccess) throw new ArgumentError(predeterminedResult);
      return new List<bool>.filled(slotLines, true, growable: false);
    }

    if (predeterminedResult == Result.criticalFailure) {
      if (!allowCriticalFailure) throw new ArgumentError(predeterminedResult);
      return new List<bool>.filled(slotLines, false, growable: false);
    }

    final valuesMin = (slotLines / 2).ceil();
    var valuesMax = slotLines;

    // If we allow criticals, make sure we don't accidentally roll one.
    if (allowCriticalSuccess && predeterminedResult == Result.success) {
      valuesMax -= 1;
    }

    if (allowCriticalFailure && predeterminedResult == Result.failure) {
      valuesMax -= 1;
    }

    final valuesTarget = valuesMin + _random.nextInt(valuesMax - valuesMin + 1);

    final value = predeterminedResult == Result.success ? true : false;
    final oppositeValue = !value;

    final values =
        new List<bool>.filled(slotLines, oppositeValue, growable: false);

    var filled = 0;

    while (filled < valuesTarget) {
      final index = _random.nextInt(slotLines);
      if (values[index] == oppositeValue) {
        values[index] = value;
        filled += 1;
      }
    }

    return values;
  }

  /// Called each frame to update the animation.
  void _update(num timeFromStartOfPage) {
    if (_timeOfStartOfRoll == null && timeFromStartOfPage != 0) {
      _timeOfStartOfRoll = timeFromStartOfPage;
    }
    num dt = timeFromStartOfPage - _lastTime;
    if (dt > _maximumDt) dt = _maximumDt; // Disallow huge dt steps.
    _lastTime = timeFromStartOfPage;

    if (_lines.every((line) => line.isFinished)) {
      resultEl.text = _currentResultText;
      _rollCompleter.complete(_currentResultText);
      return;
    }

    for (int i = 0; i < slotLines; i++) {
      final line = _lines[i];
      _currentResults[i] = line.currentResult;
      if (_timeOfStartOfRoll != null &&
          _lastTime - _timeOfStartOfRoll > line.fullSpeedMilliseconds) {
        line.isSlowingDown = true;
      }
      line.update(dt);
    }

    // Draw the gradient overlay.
    _ctx.fillStyle = _gradient;
    _ctx.fillRect(0, 0, width * slotLines, _height * 3);

    // Fade in.
    if (_timeOfStartOfRoll != null &&
        _lastTime - _timeOfStartOfRoll < _fadeInMilliseconds) {
      _ctx.fillStyle = "rgba(255, 255, 255, "
          "${1 - (_lastTime - _timeOfStartOfRoll) / _fadeInMilliseconds})";
      _ctx.fillRect(0, 0, width * slotLines, _height * 3);
    }

    resultEl.text = _currentResultText;

    window.animationFrame.then(_update);
  }
}
