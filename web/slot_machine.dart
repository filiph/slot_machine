import 'dart:html';

import 'package:slot_machine/slot_machine.dart';

void main() {
  var container = querySelector("#slot_container");
  
  querySelector("#sample_text_id").onClick.listen((_) {
    container.children.clear();

    var slotMachine = new SlotMachineAnimation.fromProbability(0.2432);
    container.append(slotMachine.canvasEl);
    container.append(slotMachine.resultEl);
    slotMachine.roll()
    .then(print);
  });
}

