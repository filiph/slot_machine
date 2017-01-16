@TestOn("dartium || browser")
import 'dart:async';
import 'dart:html';

import 'package:slot_machine/slot_machine.dart';
import "package:test/test.dart";

void main() {
  group("with steady animationFrame", () {
    test("a 99% SlotMachine can consistently fail when predetermined", () {
      _testResultAsPredetermined(
          Result.failure, 0.99, new _SteadyAnimationFrame());
    });

    test("a 1% SlotMachine can consistently succeed when predetermined", () {
      _testResultAsPredetermined(
          Result.success, 0.01, new _SteadyAnimationFrame());
    });
  });

  group("with flaky animationFrame", () {
    test("a 99% SlotMachine can consistently fail when predetermined", () {
      _testResultAsPredetermined(
          Result.failure, 0.99, new _FlakyAnimationFrame());
    });

    test("a 1% SlotMachine can consistently succeed when predetermined", () {
      _testResultAsPredetermined(
          Result.success, 0.01, new _FlakyAnimationFrame());
    });
  });

  test("a 90% predetermined to fail will always generate itself", () {
    for (int i = 0; i < 1000; i++) {
      expect(
          () => new SlotMachine.fromProbability(0.9,
                  predeterminedResult: Result.failure)
              .roll(),
          returnsNormally);
    }
  });

  test("a 100% predetermined to fail will throw", () {
    expect(
        () => new SlotMachine.fromProbability(1.0,
            predeterminedResult: Result.failure),
        throwsArgumentError);
  });
}

num _maxFrameLength = 1666.1;

num _mediumFrameLength = 30.2;

num _minFrameLength = 16.6;

void _testResultAsPredetermined(Result result, num probability,
    _AnimationFrameProvider animationFrameProvider) {
  final machine = new SlotMachine.fromProbability(probability,
      predeterminedResult: result,
      animationFrame: animationFrameProvider.animationFrame);
  document.body.append(machine.canvasEl);
  document.body.append(machine.resultEl);
  final rollResult = machine.roll();
  expect(rollResult, completion(result));
}

// ignore: one_member_abstracts
abstract class _AnimationFrameProvider {
  Future<num> animationFrame();
}

class _FlakyAnimationFrame implements _AnimationFrameProvider {
  num _time = 0;

  @override
  Future<num> animationFrame() {
    num frameLength;
    switch (_time.round() % 3) {
      case 0:
        frameLength = _minFrameLength;
        break;
      case 1:
        frameLength = _mediumFrameLength;
        break;
      case 2:
        frameLength = _maxFrameLength;
        break;
    }
    _time += frameLength;
    return new Future.value(_time);
  }
}

class _SteadyAnimationFrame implements _AnimationFrameProvider {
  num _time = 0;

  @override
  Future<num> animationFrame() {
    _time += _mediumFrameLength;
    return new Future.value(_time);
  }
}
