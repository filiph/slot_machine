@TestOn("dartium || browser")
import 'dart:html';

import 'package:slot_machine/slot_machine.dart';
import "package:test/test.dart";

void main() {
  test("a 99% can consistently fail when predetermined", () {
    int count = 0;
    for (int i = 0; i < 100; i++) {
      var machine = new SlotMachineAnimation.fromProbability(0.99,
          predeterminedResult: Result.failure);
      document.body.append(machine.canvasEl);
      document.body.append(machine.resultEl);
      var result = machine.roll();
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
    for (int i = 0; i < 10000; i++) {
      expect(() => new SlotMachineAnimation.fromProbability(0.9,
          predeterminedResult: Result.failure), returnsNormally);
    }
  });
}
