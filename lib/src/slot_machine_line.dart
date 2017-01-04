part of slot_machine;

class _SlotMachineLine {
  static const int slotCount = 10;

  static const int minFullSpeedMilliseconds = 500;

  /// The injected random instance.
  final Random _random;

  static const int _minInitialSpeed = 10000;

  static const int _resolution = 1000000;

  /// Speed at which drag stops and the slot just linearly goes to the next
  /// central position.
  static const num minSpeed = 1000;

  /// The amount of 'safe' space where we don't want to land when we
  /// predetermine result.
  ///
  /// If this was `0`, any variance in rounding could mean that we end up
  /// under- or over-shooting our desired position.
  static const double _randomOffsetMargin = 0.3;

  final int _successSymbolsCount;

  final int leftOffset;

  final int width;

  final int height;

  /// The result that this slot line should end up with.
  ///
  /// Can be `null`. `true` means success, `false` means failure.
  final bool predeterminedResult;

  int fullSpeedMilliseconds;

  final CanvasRenderingContext2D _ctx;

  int topOffset = 0;

  int speed;

  int drag = 5;

  bool isSlowingDown = false;

  bool isFinished = false;

  final CanvasImageSource successSource;

  final CanvasImageSource failureSource;

  int _pos = 0;

  bool currentResult;

  List<bool> _values;

  _SlotMachineLine(
      this._successSymbolsCount,
      this._ctx,
      this.leftOffset,
      this.width,
      this.height,
      this.successSource,
      this.failureSource,
      this._random,
      {this.predeterminedResult}) {
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
    speed = _minInitialSpeed + (_random.nextInt(_minInitialSpeed) / 10).round();

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

  int setupForPredeterminedResult() {
    assert(predeterminedResult != null);

    if (_values.every((value) => value != predeterminedResult)) {
      throw new ArgumentError("Cannot end up with $predeterminedResult when "
          "values of slot are $_values (all success or all failure).");
    }

    int index = _random.nextInt(slotCount);
    while (_values[index] != predeterminedResult) {
      index = (index + 1) % slotCount;
    }

    /// Create target position.
    final margin = (_randomOffsetMargin * height).round();
    final randomOffset = margin + _random.nextInt(height - 2 * margin);
    int pos = (((index + 1) * height + randomOffset) * _resolution).round();

    int speed = minSpeed;
    while (speed < this.speed) {
      // Do this until speed reaches the initial [_SlotMachineLine.speed].
      final dt = SlotMachineAnimation._maximumDt ~/ 5;
      pos -= (dt * speed * height).round();
      speed += drag * dt;
      // TODO: make a single computation out of this loop - integral
    }

    pos -= fullSpeedMilliseconds * this.speed * height;

    return pos;
  }

  void update(num dt) {
    if (isSlowingDown && !isFinished) {
      if (speed <= minSpeed) {
        if (((_pos / _resolution) % height).abs() < height / 20) {
          speed = 0;
          isFinished = true;
        }
      } else {
        speed -= (drag * dt).round();
      }
    }

    clear();

    if (!isFinished) {
      _pos += (dt * speed * height).round();
    }

    final normalizedPos = (_pos / _resolution) % (height * slotCount);

    final topIndex = (normalizedPos / height).floor();
    currentResult = _values[(topIndex - 2) % slotCount];
    for (int i = 0; i < 3 + 1; i++) {
      final index = topIndex - i;
      drawSquare((normalizedPos % height) - height + (height * i),
          _values[index % slotCount]);
    }
  }
}