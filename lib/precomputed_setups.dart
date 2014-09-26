
const Map<num,List<num>> PRECOMPUTED_SETUPS = const {
  0: const [0.0, 0.0, 0.0, 0.0, 0.0],
  5: const [0.2, 0.1, 0.4, 0.2, 0.1],
  10: const [0.4, 0.0, 0.4, 0.2, 0.3],
  15: const [0.4, 0.5, 0.3, 0.1, 0.2],
  20: const [0.2, 0.5, 0.2, 0.6, 0.2],
  25: const [0.4, 0.3, 0.4, 0.3, 0.4],
  30: const [0.1, 0.5, 0.5, 0.7, 0.2],
  35: const [0.5, 0.5, 0.2, 0.5, 0.4],
  40: const [0.2, 0.2, 0.9, 0.4, 0.6],
  45: const [0.3, 0.9, 0.4, 0.5, 0.3],
  50: const [0.5, 0.5, 0.5, 0.4, 0.6],
  55: const [0.6, 0.7, 0.1, 0.5, 0.7],
  60: const [0.7, 0.5, 0.1, 0.6, 0.8],
  65: const [0.5, 0.8, 0.6, 0.5, 0.5],
  70: const [0.9, 0.5, 0.8, 0.5, 0.3],
  75: const [0.7, 0.6, 0.6, 0.6, 0.7],
  80: const [0.8, 0.8, 0.8, 0.5, 0.4],
  85: const [0.8, 0.6, 0.5, 0.9, 0.7],
  90: const [0.6, 1.0, 0.7, 0.6, 0.8],
  95: const [0.8, 0.6, 0.9, 0.9, 0.8],
  100: const [0.8, 1.0, 1.0, 1.0, 0.7]
};

const PRECISION_STEPS = 5;

List<num> getPrecomputedSetup(num desiredProbability) {
  num probability = desiredProbability * 100 / PRECISION_STEPS;  // ex. 6.4
  probability = probability.round();  // ex. 6.0
  probability *= PRECISION_STEPS;  // ex. 60
  
  return PRECOMPUTED_SETUPS[probability];
}

/// Returns the number in the iterable that is closest to the target number. 
/// When there are several numbers with the same delta to [target], the last
/// one is taken.
num findClosest(num target, Iterable<num> list) {
  num min = double.INFINITY;
  num closest = target;
  
  for (num v in list) {
    final num diff = (v - target).abs();
  
    if (diff < min) {
      min = diff;
      closest = v;
    }
  }
  
  return closest;
}