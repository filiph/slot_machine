import 'dart:html';

import 'package:slot_machine/slot_machine.dart';

void main() {
  final container = querySelector("#slot_container");
  final resultEl = querySelector("#slot_result");
  final RangeInputElement probabilityEl = querySelector("#probability");
  final probabilitySpan = querySelector("#probability_span");
  final startButton = querySelector("#start_button");

  num probability = 0.75;
  probabilityEl.onChange.listen((_) {
    probability = probabilityEl.valueAsNumber / 100;
    probabilitySpan.text = "${probabilityEl.value}%";
  });

  startButton.onClick.listen((_) {
    container.children.clear();
    resultEl.children.clear();

    final slotMachine = new SlotMachineAnimation.fromProbability(probability,
        predeterminedResult: Result.failure);
    container.append(slotMachine.canvasEl);
    resultEl.append(slotMachine.resultEl);
    slotMachine.roll().then(print);
  });
}
