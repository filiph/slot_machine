import 'dart:html';

import 'package:slot_machine/slot_machine.dart';

void main() {
  final container = querySelector("#slot_container");
  final resultEl = querySelector("#slot_result");
  final RangeInputElement probabilityEl = querySelector("#probability");
  final probabilitySpan = querySelector("#probability_span");
  final randomButton = querySelector("#random_button");
  final successButton = querySelector("#success_button");
  final failButton = querySelector("#fail_button");

  // Allow setting up probability.
  num probability = 0.75;
  probabilityEl.onChange.listen((_) {
    probability = probabilityEl.valueAsNumber / 100;
    probabilitySpan.text = "${probabilityEl.value}%";
  });

  // Handle click of buttons.
  void handle(Result predeterminedResult) {
    container.children.clear();
    resultEl.children.clear();

    final slotMachine = new SlotMachine.fromProbability(probability,
        predeterminedResult: predeterminedResult);
    container.append(slotMachine.canvasEl);
    resultEl.append(slotMachine.resultEl);
    slotMachine.roll().then(print);
  }

  randomButton.onClick.listen((_) => handle(null));
  successButton.onClick.listen((_) => handle(Result.success));
  failButton.onClick.listen((_) => handle(Result.failure));
}
