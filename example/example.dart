import 'dart:html';

import 'package:slot_machine/slot_machine.dart';

void main() {
  final container = querySelector("#slot_container");
  final rerollContainer = querySelector("#reroll_container");
  final resultEl = querySelector("#slot_result");
  final RangeInputElement probabilityEl = querySelector("#probability");
  final probabilitySpan = querySelector("#probability_span");
  final randomButton = querySelector("#random_button");

  // Allow setting up probability.
  num probability = 0.75;
  probabilityEl.onChange.listen((_) {
    probability = probabilityEl.valueAsNumber / 100;
    probabilitySpan.text = "${probabilityEl.value}%";
  });

  // Handle click of buttons.
  void handle(_) {
    container.children.clear();
    rerollContainer.children.clear();
    resultEl.children.clear();

    final slotMachine = new SlotMachine(probability,
        rerollable: true, rerollEffectDescription: "use coin");
    container.append(slotMachine.canvasEl);
    rerollContainer.append(slotMachine.rerollEl);
    resultEl.append(slotMachine.resultEl);
    slotMachine.play().then(print);
  }

  randomButton.onClick.listen(handle);
}
