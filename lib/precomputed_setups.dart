library slot_machine_precomputed_setups;

/// The percentage steps of [precomputedSetups].
///
/// For example, if this is `5`, then we'll have precomputed setups for 0%, 5%,
/// 10%, 15%, and so on.
const int precisionSteps = 5;

/// A map that was populated by running [:bin/compute_setup.dart:]. The setups
/// will produce slot machines that will produce successes with the appropriate
/// probability.
///
/// These setups hold true when number of slot lines is 5 and number of slots
/// (images) per each line is 10.
const Map<num, List<int>> precomputedSetups = const {
  0: const [0, 0, 0, 0, 0],
  5: const [2, 1, 4, 2, 1],
  10: const [4, 0, 4, 2, 3],
  15: const [4, 5, 3, 1, 2],
  20: const [2, 5, 2, 6, 2],
  25: const [4, 3, 4, 3, 4],
  30: const [1, 5, 5, 7, 2],
  35: const [5, 5, 2, 5, 4],
  40: const [2, 2, 9, 4, 6],
  45: const [3, 9, 4, 5, 3],
  50: const [5, 5, 5, 4, 6],
  55: const [6, 7, 1, 5, 7],
  60: const [7, 5, 1, 6, 8],
  65: const [5, 8, 6, 5, 5],
  70: const [9, 5, 8, 5, 3],
  75: const [7, 6, 6, 6, 7],
  80: const [8, 8, 8, 5, 4],
  85: const [8, 6, 5, 9, 7],
  90: const [6, 10, 7, 6, 8],
  95: const [8, 6, 9, 9, 8],
  100: const [8, 10, 10, 10, 7]
};

/// Returns the number in the iterable that is closest to the target number.
/// When there are several numbers with the same delta to [target], the last
/// one is taken.
num findClosest(num target, Iterable<num> list) {
  num min = double.INFINITY;
  num closest;

  for (num v in list) {
    final num diff = (v - target).abs();

    if (diff < min) {
      min = diff;
      closest = v;
    }
  }

  if (closest == null) {
    throw new ArgumentError("provided list was empty");
  }

  return closest;
}

/// Takes a probability of success that we want to see from the slot machine
/// as a whole and returns precomputed setup that will create such slot machine.
List<int> getPrecomputedSetup(num desiredProbability) {
  num probability = desiredProbability * 100 / precisionSteps; // ex. 6.4
  probability = probability.round(); // ex. 6.0
  probability *= precisionSteps; // ex. 60

  return precomputedSetups[probability];
}
