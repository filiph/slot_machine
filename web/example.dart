import 'dart:html';

import 'package:slot_machine/slot_machine.dart';

void main() {
  var container = querySelector("#slot_container");
  var resultEl = querySelector("#slot_result");
  
  querySelector("#sample_text_id").onClick.listen((_) {
    container.children.clear();
    resultEl.children.clear();

    var slotMachine = new SlotMachineAnimation.fromProbability(0.66);
//    slotMachine.allowCriticalSuccess = false;
//    slotMachine.allowCriticalFailure = false;
    container.append(slotMachine.canvasEl);
    resultEl.append(slotMachine.resultEl);
    slotMachine.roll()
    .then(print);
  });
}

