part of slot_machine;

class _SlotMachineLine {
  static const int slotCount = 10;

  static const int minFullSpeedMilliseconds = 500;

  static final Random _random = new Random();

  final num probability;

  final int leftOffset;

  final int width;

  final int height;

  num fullSpeedMilliseconds;

  final CanvasRenderingContext2D _ctx;

  num topOffset = 0;

  num speed = 0.01;

  num drag = 0.0001;

  bool isSlowingDown = false;

  bool isFinished = false;

  final CanvasImageSource successSource;

  final CanvasImageSource failureSource;

  num _pos = 0;

  bool currentResult;

  List<bool> _values;

  _SlotMachineLine(this.probability, this._ctx, this.leftOffset, this.width,
      this.height, this.successSource, this.failureSource) {
    _values = new List<bool>.filled(slotCount, false);

    final successValuesTarget = (slotCount * probability).round();
    int successValuesCurrent = 0;
    while (successValuesCurrent < successValuesTarget) {
      final index = _random.nextInt(slotCount);
      if (_values[index] == false) {
        _values[index] = true;
        successValuesCurrent += 1;
      }
    }

    fullSpeedMilliseconds = minFullSpeedMilliseconds + _random.nextInt(2000);
    speed += speed * (_random.nextDouble() / 10);

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

  void update(num dt) {
    if (isSlowingDown && !isFinished) {
      if (speed <= 0.001) {
        if ((_pos % height).abs() < height / 20) {
          speed = 0;
          isFinished = true;
        }
      } else {
        speed -= drag;
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
