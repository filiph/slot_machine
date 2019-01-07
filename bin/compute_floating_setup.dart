/// Computes what the probability should be set for each wheel if
/// there are five of them and success is 3+ successful wheels.
library compute_floating_setup;

import 'dart:math';

void main() {
  for (int i = 0; i <= 100; i++) {
    final p = i / 100;
    print('$p, ${computeTotalProbability(p)}');
  }
}

double computeTotalProbability(double wheelProbability, [int wheelCount = 5]) {
  final possibleResults = getPossibleResults(wheelCount);

  // print("count: ${possibleResults.length}");
  
  // print(possibleResults);
  // print(possibleResults.where((result) => result.isWinning).length);

  var total = 0.0;
  var winningTotal = 0.0;
  for (final result in possibleResults) {
    final partial = result.probability(wheelProbability);
    // print("$result (${result.isWinning ? 'win' : 'lose'}) = $partial");
    total += partial;
    winningTotal += result.isWinning ? partial : 0;
  }

  // print(total);
  return winningTotal;
}

List<Result> getPossibleResults(int wheelCount) {
  final pools =
      List<List<bool>>.filled(wheelCount, const [true, false], growable: false);
  final set = product(pools);
  assert(
      set.length == pow(2, wheelCount), "The resulting set should be n ** r.");
  return set.map((result) => Result(result)).toList(growable: false);
}

/// Returns Cartesian product of a list of [pools].
/// https://en.wikipedia.org/wiki/Cartesian_product
Iterable<List<T>> product<T>(List<List<T>> pools) sync* {
  if (pools.length < 2) throw ArgumentError(pools);
  if (pools.length == 2) {
    for (final x in pools.first) {
      for (final y in pools.last) {
        yield [x, y];
      }
    }
    return;
  }

  for (final x in pools.first) {
    for (final y in product(pools.sublist(1))) {
      yield [x] + y;
    }
  }
}

class Result {
  final List<bool> wheelResults;

  const Result(this.wheelResults);

  bool get isWinning =>
      wheelResults.where((result) => result).length > wheelResults.length / 2;

  /// Probability that this exact result will be shown, given probability
  /// setting of each wheel.
  double probability(double wheelProbability) {
    double result = 1.0;
    for (final wheelResult in wheelResults) {
      if (wheelResult) {
        result *= wheelProbability;
      } else {
        result *= (1 - wheelProbability);
      }
    }
    return result;
  }

  @override
  String toString() => wheelResults.toString();
}
