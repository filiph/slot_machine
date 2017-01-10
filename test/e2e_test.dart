@TestOn("dartium || browser")
import 'dart:html';

import 'package:slot_machine/slot_machine.dart';
import "package:test/test.dart";

void main() {
  test("a 99% can consistently fail when predetermined", () {
    int count = 0;
    for (int i = 0; i < 100; i++) {
      final machine = new SlotMachineAnimation.fromProbability(0.99,
          predeterminedResult: Result.failure);
      document.body.append(machine.canvasEl);
      document.body.append(machine.resultEl);
      final result = machine.roll();
      result.then(expectAsync1((result) {
        if (result != Result.failure) {
          print("bad result with $i: $result "
              "(element: ${machine.resultEl.text})");
          count += 1;
          print("bad results: $count");
        }
      }));
//      expect(result, completion(Result.failure), reason: "run $i didn't fail");
    }
  }, skip: true);

  test("a 90% predetermined to fail will always generate itself", () {
    for (int i = 0; i < 1000; i++) {
      expect(
          () => new SlotMachineAnimation.fromProbability(0.9,
                  predeterminedResult: Result.failure)
              .roll(),
          returnsNormally);
    }
  });

  test("a 100% predetermined to fail will throw", () {
    expect(
        () => new SlotMachineAnimation.fromProbability(1.0,
            predeterminedResult: Result.failure),
        throwsArgumentError);
  });
}
