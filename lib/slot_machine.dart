library slot_machine;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:slot_machine/precomputed_setups.dart' show getPrecomputedSetup;
import 'package:slot_machine/result.dart';

export 'package:slot_machine/result.dart';

part 'src/reel.dart';

/// A function type that allows users of this library to provide their own
/// [Window.animationFrame].
typedef Future<num> AnimationFrameFunction();

/// A class that creates the slot machine.
///
/// It currently only creates slot machines with 5 slot lines, 10 images each.
/// The slot machine is visualized through 2 DOM elements. [canvasEl] shows
/// the slot machine itself, with rotating slots. [resultEl] is a span element
/// that automatically populates with the current outcome in real time.
///
/// The SlotMachine is single-serving, i.e. it cannot be rolled more
/// than once.
class SlotMachine {
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

  /// Number of symbols in each reel.
  static const int symbolCount = 10;

  /// The number of reels (vertical lines) per each machine.
  static const int reelCount = 5;

  /// The width of each reel in pixels.
  final int width = 40;

  /// The height of each symbol. By default it's the same as width.
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

  List<_Reel> _reels;

  Completer<Result> _rollCompleter;

  final AnimationFrameFunction _animationFrame;

  num _lastTime = 0;

  num _timeOfStartOfRoll;

  /// A list of booleans evaluating the slots from left to right.
  List<bool> _currentResults;

  /// Create a slot machine animation with probability of success (of the whole
  /// machine) being [probability].
  factory SlotMachine.fromProbability(num probability,
      {Result predeterminedResult, AnimationFrameFunction animationFrame}) {
    if (probability == 0 && predeterminedResult == Result.success) {
      throw new ArgumentError("Cannot have predetermined $predeterminedResult "
          "with probability of $probability.");
    }
    if (probability == 1 && predeterminedResult == Result.failure) {
      throw new ArgumentError("Cannot have predetermined $predeterminedResult "
          "with probability of $probability.");
    }
    if (probability < 0 || probability > 1) {
      throw new ArgumentError("Probability must be between 0 and 1. Provided "
          "value: $probability.");
    }
    final setup = getPrecomputedSetup(probability);
    return new SlotMachine._(setup,
        predeterminedResult: predeterminedResult,
        animationFrame: animationFrame);
  }

  /// Create a [SlotMachine] by giving probability of success per
  /// each slot with [reelSuccessCounts].
  ///
  /// Indicate what kinds of results to allow with [allowCriticalSuccess]
  /// and [allowCriticalFailure].
  SlotMachine._(List<int> reelSuccessCounts,
      {this.allowCriticalSuccess: false,
      this.allowCriticalFailure: false,
      Result predeterminedResult,
      AnimationFrameFunction animationFrame})
      : _animationFrame = animationFrame {
    assert(reelSuccessCounts.length == reelCount);

    _height = width;

    canvasEl = new CanvasElement(width: width * reelCount, height: width * 3);
    _ctx = canvasEl.context2D;
    resultEl = new SpanElement();

    final predeterminedValues =
        _fillPredeterminedValues(reelSuccessCounts, predeterminedResult);

    _reels = new List<_Reel>(reelCount);
    for (int i = 0; i < reelCount; i += 1) {
      _reels[i] = new _Reel(reelSuccessCounts[i], _ctx, i * width, width,
          _height, _successIcon, _failureIcon, _random,
          predeterminedResult: predeterminedValues[i]);
    }
    _currentResults = new List<bool>(reelCount);

    if (reelCount % 2 == 0) {
      throw new ArgumentError("Reels need to be an odd number.");
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

  Result get _currentResult {
    if (_currentResults.any((result) => result == null)) {
      throw new StateError("Tried calling _currentResult when some results "
          "are null.");
    }
    final positives = _currentResults.fold(
        0, (int sum, bool result) => sum += result ? 1 : 0);
    final negatives = reelCount - positives;

    if (allowCriticalSuccess && positives == reelCount) {
      return Result.criticalSuccess;
    }
    if (allowCriticalFailure && negatives == reelCount) {
      return Result.criticalFailure;
    }
    if (positives > negatives) return Result.success;
    if (positives < negatives) return Result.failure;

    throw new StateError("Cannot decide success or fail. "
        "slotCount should be odd.");
  }

  String get _currentResultText {
    switch (_currentResult) {
      case Result.criticalSuccess:
        return _criticalSuccessMsg;
      case Result.success:
        return _successMsg;
      case Result.failure:
        return _failureMsg;
      case Result.criticalFailure:
        return _criticalFailureMsg;
      default:
        throw new StateError("No result");
    }
  }

  /// Start rolling the slot machine. Returns with the text of the result.
  Future<Result> roll() {
    if (_rollCompleter != null) {
      throw new StateError("Cannot roll one slot machine twice.");
    }
    _rollCompleter = new Completer<Result>();

    Future
        .wait([_successIcon.onLoad.first, _failureIcon.onLoad.first]).then((_) {
      _update(0);
    });

    return _rollCompleter.future;
  }

  List<bool> _fillPredeterminedValues(
      List<int> reelSuccessCounts, Result predeterminedResult) {
    if (predeterminedResult == null) {
      return new List<bool>.filled(reelCount, null, growable: false);
    }

    if (predeterminedResult == Result.criticalSuccess) {
      if (!allowCriticalSuccess) throw new ArgumentError(predeterminedResult);
      assert(reelSuccessCounts.every((count) => count > 0));
      return new List<bool>.filled(reelCount, true, growable: false);
    }

    if (predeterminedResult == Result.criticalFailure) {
      if (!allowCriticalFailure) throw new ArgumentError(predeterminedResult);
      assert(reelSuccessCounts.every((count) => count < symbolCount));
      return new List<bool>.filled(reelCount, false, growable: false);
    }

    final valuesMin = (reelCount / 2).ceil();
    final neededValue = predeterminedResult == Result.success ? true : false;
    final values = new List<bool>.filled(reelCount, null, growable: false);

    // Automatically assign values to reels that have all success or all
    // failure symbols.
    for (int i = 0; i < reelCount; i += 1) {
      if (reelSuccessCounts[i] == 0) {
        values[i] = false;
        continue;
      }

      if (reelSuccessCounts[i] == symbolCount) {
        values[i] = true;
      }
    }

    // Compute how many desired values we already have filled.
    var filled =
        values.fold(0, (prev, el) => prev + (el == neededValue ? 1 : 0));

    while (filled < valuesMin) {
      final index = _random.nextInt(reelCount);
      if (values[index] == null) {
        values[index] = neededValue;
        filled += 1;
      }
    }

    // Make sure we don't accidentally roll critical success or failure when
    // allowed (but not predetermined).
    if (allowCriticalSuccess && predeterminedResult == Result.success) {
      _switchOneNullToValue(values, false, reelSuccessCounts);
    }
    if (allowCriticalFailure && predeterminedResult == Result.failure) {
      _switchOneNullToValue(values, true, reelSuccessCounts);
    }

    return values;
  }

  void _switchOneNullToValue(
      List<bool> values, bool value, List<int> reelSuccessCounts) {
    int index = _random.nextInt(reelCount);
    int tries = 0;
    while (values[index] != null) {
      index = (index + 1) % SlotMachine.symbolCount;
      tries += 1;
      if (tries > symbolCount) {
        throw new ArgumentError("Cannot prevent critical success or failure "
            "with given reelSuccessCounts: $reelSuccessCounts.");
      }
    }

    values[index] = value;
  }

  /// Called each frame to update the animation.
  void _update(num timeFromStartOfPage) {
    if (_timeOfStartOfRoll == null && timeFromStartOfPage != 0) {
      _timeOfStartOfRoll = timeFromStartOfPage;
    }
    num dt = timeFromStartOfPage - _lastTime;
    if (dt > _maximumDt) dt = _maximumDt; // Disallow huge dt steps.
    _lastTime = timeFromStartOfPage;

    if (_reels.every((line) => line.isFinished)) {
      resultEl.text = _currentResultText;
      _rollCompleter.complete(_currentResult);
      return;
    }

    for (int i = 0; i < reelCount; i++) {
      final reel = _reels[i];
      reel.update(dt);
      _currentResults[i] = reel.currentResult;
    }

    // Draw the gradient overlay.
    _ctx.fillStyle = _gradient;
    _ctx.fillRect(0, 0, width * reelCount, _height * 3);

    // Fade in.
    if (_timeOfStartOfRoll != null &&
        _lastTime - _timeOfStartOfRoll < _fadeInMilliseconds) {
      _ctx.fillStyle = "rgba(255, 255, 255, "
          "${1 - (_lastTime - _timeOfStartOfRoll) / _fadeInMilliseconds})";
      _ctx.fillRect(0, 0, width * reelCount, _height * 3);
    }

    resultEl.text = _currentResultText;

    if (_animationFrame != null) {
      _animationFrame().then(_update);
    } else {
      window.animationFrame.then(_update);
    }
  }
}
