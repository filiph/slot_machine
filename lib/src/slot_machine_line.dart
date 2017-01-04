part of slot_machine;

class _SlotMachineLine {
  static const int slotCount = 10;

  static const int minFullSpeedMilliseconds = 500;

  static final Random _random = new Random();

  final int _successSymbolsCount;

  final int leftOffset;

  final int width;

  final int height;

  final Result predeterminedResult;

  num fullSpeedMilliseconds;

  final CanvasRenderingContext2D _ctx;

  num topOffset = 0;

  num speed = 0.01;

  num drag = 0.000005;

  static const int _resolution = 1000000;

  bool isSlowingDown = false;

  bool isFinished = false;

  final CanvasImageSource successSource;

  final CanvasImageSource failureSource;

  num _pos = 0;

  bool currentResult;

  List<bool> _values;

  _SlotMachineLine(this._successSymbolsCount, this._ctx, this.leftOffset, this.width,
      this.height, this.successSource, this.failureSource, {this.predeterminedResult}) {
    _values = new List<bool>.filled(slotCount, false);

    int successValuesCurrent = 0;
    while (successValuesCurrent < _successSymbolsCount) {
      final index = _random.nextInt(slotCount);
      if (_values[index] == false) {
        _values[index] = true;
        successValuesCurrent += 1;
      }
    }

    fullSpeedMilliseconds = minFullSpeedMilliseconds + _random.nextInt(2000);
    speed += speed * (_random.nextDouble() / 10);

    if (predeterminedResult != null) {
      _pos = setupForPredeterminedResult();
    }

    // Fail otherwise, because our assets are 40x40.
    assert(width == 40);
    assert(height == 40);
  }

  void clear() {
    _ctx.fillStyle = '#ffffff';
    _ctx.fillRect(leftOffset, 0, width, height * 3);
  }

  void drawSquare(num topOffset, bool value) {
    _ctx.drawImage(
        value ? successSource : failureSource, leftOffset, topOffset);
  }

  num setupForPredeterminedResult() {
    assert(predeterminedResult != null);
    assert(predeterminedResult != Result.criticalSuccess); // Don't use for slot line
    assert(predeterminedResult != Result.criticalFailure);

    final predeterminedValue = predeterminedResult == Result.success ? true : false;

    if (_values.every((value) => value != predeterminedValue)) {
      throw new ArgumentError("Cannot end up with $predeterminedResult when "
          "values of slot are $_values (all success or all failure).");
    }

    int index = _random.nextInt(slotCount);
    while (_values[index] != predeterminedValue) {
      index = (index + 1) % slotCount;
    }

    /// Create target position.
    num pos = index * height + 1.5 * height;

    num speed = minSpeed;
    while (speed < this.speed) {
      // Do this until speed reaches the initial [_SlotMachineLine.speed].
      final dt = SlotMachineAnimation._maximumDt / 2;
      pos -= dt * speed * height;
      speed += drag * dt;
      // TODO: make a single computation out of this loop - integral
    }

    pos -= fullSpeedMilliseconds * this.speed * height;

    return pos;
//    - TODO: make speed & pos an int so that there is zero rounding error
//    - TODO: test (and fix) for very long pauses in execution
  }

  static const num minSpeed = 0.001;

  void update(num dt) {
    if (isSlowingDown && !isFinished) {
      if (speed <= minSpeed) {
        if ((_pos % height).abs() < height / 20) {
          speed = 0;
          isFinished = true;
        }
      } else {
        speed -= drag * dt;
      }
    }

    clear();

    if (!isFinished) {
      _pos += (dt * speed * height);
    }

    final normalizedPos = _pos % (height * slotCount);

    final topIndex = (normalizedPos / height).floor();
    currentResult = _values[(topIndex - 2) % slotCount];
    for (int i = 0; i < 3 + 1; i++) {
      final index = topIndex - i;
      drawSquare((normalizedPos % height) - height + (height * i),
          _values[index % slotCount]);
    }
  }
}
