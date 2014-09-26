
import 'dart:math';
import 'package:slot_machine/precomputed_setups.dart' show findClosest;

void main() {


//  for (int desiredPctPoints = 0; desiredPctPoints <= 100; 
//      desiredPctPoints += 5) {
//    num desiredProbability = desiredPctPoints / 100;
//    print("Finding setup for desired probability $desiredProbability.");
//    var setup = findSlotLineSetup(desiredProbability, slotCount: 10);
//    
//    print(setup);
//    print(getSlotLineProbabilitiesFromSetup(setup));
//    computeSlotMachineProbability(setup);    
//  }
  
  
  // Brute force
  Map<num,List<num>> probabilities = new Map<num,List<num>>();
  for (num probabilityOfSuccessSlot = 0; probabilityOfSuccessSlot <= 1.0; 
      probabilityOfSuccessSlot += 0.0001) {
    print("===");
    print("Creating random setup for slot probability $probabilityOfSuccessSlot.");
    var setup = createRandomSetup(probabilityOfSuccessSlot, 5, 10);
    
    var probSuccess = _getSuccessProbability(setup);
    //probSuccess = (probSuccess * 100).round() / 100;
    if (probabilities.containsKey(probSuccess)) continue;
    
    probabilities[probSuccess] = getSlotLineProbabilitiesFromSetup(setup);
    print("Probability = $probSuccess");
  }
  
  var keys = probabilities.keys.toList();
  keys.sort();
  print(keys);
  
  int step = 5;
  for (int target = 0; target <= 100; target += step) {
    num closest = findClosest(target / 100, keys);
    print("${target / 100}: ${probabilities[closest]},");
  }
  
  print(probabilities);
}



List<List<bool>> createRandomSetup(num probabilityOfSuccessSlot, 
    int slotLinesCount, int slotCount) {
  Random random = new Random();
  List<List<bool>> setup = new List(slotLinesCount);
  for (int i = 0; i < slotLinesCount; i++) {
    setup[i] = new List<bool>.filled(slotCount, false);
    for (int j = 0; j < slotCount; j++) {
      setup[i][j] = random.nextDouble() < probabilityOfSuccessSlot;
    }
  }
  
  return setup;
}

List<num> getSlotLineProbabilitiesFromSetup(List<List<bool>> setup) {
  return new List<num>.from(setup.map((List<bool> line) => line.where((v) => v).length / line.length));
}

/// Computes probabilities of success and failure depending on setup.
void computeSlotMachineProbability(List<List<bool>> setup) {
  List<int> outcomes = _generatePossibleOutcomes(setup);
  
  int slotLinesCount = setup.length;
  int slotCount = setup[0].length;
  
  int count = outcomes.length;
  int criticalSuccesses = outcomes.where((o) => o == slotLinesCount).length;
  int successes = outcomes.where((o) => o > 0).length;
  int failures = outcomes.where((o) => o < 0).length;
  int criticalFailures = outcomes.where((o) => o == -slotLinesCount).length;
  
  print("Successes:           $successes\t(${successes / count})");
  print("Failures:            $failures\t(${failures / count})");
  print("Critical Successes:  $criticalSuccesses\t(${criticalSuccesses / count})");
  print("Critical Failures:   $criticalFailures\t(${criticalFailures / count})");
}

List<List<bool>> findSlotLineSetup(num desiredProbability, 
    {int slotLinesCount: 5, int slotCount: 10, int maxTries: 100,
     num delta: 0.01}) {
  bool fillValue;
  num currentProbability;
  Random random = new Random();
  if (desiredProbability > 0.66) {
    fillValue = true;
    currentProbability = 1.0;
  } else if (desiredProbability < 0.33) {
    fillValue = false;
    currentProbability = 0.0;
  } else {
    fillValue = null;
    currentProbability = 0.5;
  }
  
  // Create initial setup.
  List<List<bool>> setup = new List(slotLinesCount);
  for (int i = 0; i < slotLinesCount; i++) {
    bool value;
    if (fillValue == null) {
      // We are starting from probability 0.5, so let's create half true,
      // half false.
      setup[i] = new List<bool>(slotCount);
      for (int j = 0; j < slotCount; j++) {
        setup[i][j] = j % 2 == 0;
      }
    } else {
      setup[i] = new List<bool>.filled(slotCount, fillValue);
    }
  }
  
  if (desiredProbability < delta || desiredProbability > 1.0 - delta ||
      (desiredProbability > 0.5 - delta && desiredProbability < 0.5 + delta)) {
    return setup;
  }
  
  int tries = maxTries;
  
  while (tries > 0) {
    tries -= 1;
//    print(setup);
//    print(currentProbability);
    
    bool boolValueToFlip = desiredProbability > currentProbability;
    
    int randomLine;
    int randomSlot;
    bool currentValue;
    // Pick a single slot to flip.
    while (true) {
      randomLine = random.nextInt(slotLinesCount);
      randomSlot = random.nextInt(slotCount);
      currentValue = setup[randomLine][randomSlot];
      if (currentValue != boolValueToFlip) {
        break;
      }
    }
    
    // Flip the random bit.
    setup[randomLine][randomSlot] = !setup[randomLine][randomSlot];
    
    // Compute the new setup's probability.
    num newProbability = _getSuccessProbability(setup);
    
    num currentDelta = (desiredProbability - currentProbability).abs();
    num newDelta = (desiredProbability - newProbability).abs();
    
    if (newDelta <= currentDelta) {
      // More successful.
      if (newDelta < delta) {
//        print("Delta is sufficiently small ($newDelta vs $delta)");
        return setup;
      }
      currentProbability = newProbability;
    } else {
      // Less successful. Revert.
      setup[randomLine][randomSlot] = !setup[randomLine][randomSlot];
    }
  }
  print("Too many tries");
  return setup;
}

num _getSuccessProbability(List<List<bool>> setup) {
  List<int> outcomes = _generatePossibleOutcomes(setup);
  int count = outcomes.length;
  int successes = outcomes.where((o) => o > 0).length;
  return successes / count;
}

List<int> _generatePossibleOutcomes(List<List<bool>> setup, 
    {int leftOffset: 0}) {
  // Compute first slot line's successes.
  int slotLinesCount = setup.length;
  int slotCount = setup[0].length;
  List<int> thisLineOutcomes = 
      new List<int>.from(setup[leftOffset].map((b) => b ? 1 : -1));
  
  if (leftOffset == slotLinesCount - 1) {
    return thisLineOutcomes;
  }
  
  List<int> wholeOutcomes = new List<int>();
  
  thisLineOutcomes.forEach((int outcome) {
    _generatePossibleOutcomes(setup, leftOffset: leftOffset + 1)
    .forEach((rightOutcome) {
      wholeOutcomes.add(outcome + rightOutcome);
    });
  });
  return wholeOutcomes;
}