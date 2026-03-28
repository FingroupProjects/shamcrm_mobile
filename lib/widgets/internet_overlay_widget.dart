import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class InternetOverlayWidget extends StatefulWidget {
  const InternetOverlayWidget({Key? key}) : super(key: key);

  @override
  State<InternetOverlayWidget> createState() => _InternetOverlayWidgetState();
}

class _InternetOverlayWidgetState extends State<InternetOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late AnimationController _pressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pressAnimation;

  bool _isGameMode = false;
  double _longPressProgress = 0.0;
  Timer? _longPressTimer;
  int _tapCount = 0;
  Timer? _tapResetTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  void _handleTap() {
    _tapCount++;
    _tapResetTimer?.cancel();

    _tapResetTimer = Timer(const Duration(seconds: 2), () {
      _tapCount = 0;
    });

    if (_tapCount >= 5) {
      _activateGame();
    }
  }

  void _handleLongPressStart() {
    _pressController.forward();
    _longPressProgress = 0.0;

    _longPressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _longPressProgress += 0.02;
        if (_longPressProgress >= 1.0) {
          timer.cancel();
          _activateGame();
        }
      });
    });
  }

  void _handleLongPressEnd() {
    _pressController.reverse();
    _longPressTimer?.cancel();
    setState(() {
      _longPressProgress = 0.0;
    });
  }

  void _activateGame() {
    _longPressTimer?.cancel();
    setState(() {
      _isGameMode = true;
      _longPressProgress = 0.0;
    });
  }

  void _closeGame() {
    setState(() {
      _isGameMode = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotateController.dispose();
    _pressController.dispose();
    _longPressTimer?.cancel();
    _tapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Material(
        color: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isGameMode
              ? _DinoJumpGame(onClose: _closeGame)
              : _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      key: const ValueKey('main'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E2E52),
            const Color(0xFF1E2E52).withOpacity(0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          _buildGeometricPattern(),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 60,
                        spreadRadius: 0,
                        offset: const Offset(0, 30),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInteractiveIcon(),
                      const SizedBox(height: 40),
                      const Text(
                        'Отсутствует подключение',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2E52),
                          fontFamily: 'Gilroy',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ожидаем восстановления связи\nс сервером',
                        style: TextStyle(
                          fontSize: 15,
                          color: const Color(0xFF1E2E52).withOpacity(0.6),
                          fontFamily: 'Golos',
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _buildLoadingDots(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveIcon() {
    return GestureDetector(
      onTap: _handleTap,
      onLongPressStart: (_) => _handleLongPressStart(),
      onLongPressEnd: (_) => _handleLongPressEnd(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_longPressProgress > 0)
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: _longPressProgress,
                strokeWidth: 4,
                backgroundColor: const Color(0xFF006FFD).withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF006FFD),
                ),
              ),
            ),
          ScaleTransition(
            scale: _pressAnimation,
            child: RotationTransition(
              turns: _rotateController,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF006FFD).withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: CustomPaint(
                  painter: _ArcPainter(
                    color: const Color(0xFF006FFD),
                  ),
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: _pressAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A90E2),
                    Color(0xFF006FFD),
                  ],
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          if (_longPressProgress > 0.1 && _longPressProgress < 1.0)
            Positioned(
              bottom: -40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF006FFD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Держите...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeometricPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GeometricPatternPainter(),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 100)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF4A90E2).withOpacity(0.3),
                  const Color(0xFF006FFD),
                  value,
                ),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {
            if (mounted) setState(() {});
          },
        );
      }),
    );
  }
}

// ============================================================================
//  MARK: DINO JUMP GAME
// ============================================================================

class _DinoJumpGame extends StatefulWidget {
  final VoidCallback onClose;

  const _DinoJumpGame({required this.onClose});

  @override
  State<_DinoJumpGame> createState() => _DinoJumpGameState();
}

class _DinoJumpGameState extends State<_DinoJumpGame>
    with TickerProviderStateMixin {
  late AnimationController _gameController;
  late AnimationController _rotateController;
  final double _groundLevel = 0;

  double _dinoY = 0;
  double _dinoVelocity = 0;
  bool _isJumping = false;

  final double _gravity = 0.8; // Быстрее падение
  final double _jumpStrength = 15.0; // Выше прыжок
  double _obstacleSpacing = 2.5; // Ближе препятствия
  final double _initialSpeed = 0.02; // ОЧЕНЬ медленный старт
  final double _maxSpeed = 1.5; // Максимальная скорость

  List<Obstacle> _obstacles = [];
  int _score = 0;
  bool _gameStarted = false;
  bool _gameOver = false;

  // === СКОРОСТЬ ПО СЧЁТУ ===
  late double _currentSpeed;

  @override
  void initState() {
    super.initState();

    _gameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateGame);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _initObstacles();
  }

  void _initObstacles() {
    _obstacles = [
      Obstacle(x: 1.2, type: ObstacleType.cactus),
      Obstacle(x: 2.4, type: ObstacleType.rock),
      Obstacle(x: 3.6, type: ObstacleType.cactus),
    ];
  }

  void _startGame() {
    if (!_gameStarted) {
      setState(() {
        _gameStarted = true;
        _gameOver = false;
        _score = 0;
        _dinoY = _groundLevel;
        _dinoVelocity = 0;
        _isJumping = false;
        _currentSpeed = _initialSpeed; // ← Начинаем медленно
      });
      _initObstacles();
      _gameController.repeat();
    }
  }

  void _jump() {
    if (_gameOver) {
      _resetGame();
      return;
    }

    if (!_gameStarted) {
      _startGame();
      return;
    }

    if (_dinoY == _groundLevel && !_isJumping) {
      setState(() {
        _dinoVelocity = _jumpStrength;
        _isJumping = true;
      });
    }
  }

  void _updateGame() {
    if (!_gameStarted || _gameOver) return;

    setState(() {
      // === ФИЗИКА ПРЫЖКА ===
      if (_isJumping || _dinoY > _groundLevel) {
        _dinoVelocity -= _gravity;
        _dinoY += _dinoVelocity;

        if (_dinoY <= _groundLevel) {
          _dinoY = _groundLevel;
          _dinoVelocity = 0;
          _isJumping = false;
        }
      }

      // === СКОРОСТЬ + РАССТОЯНИЕ ПО СЧЁТУ ===
// === СКОРОСТЬ + РАССТОЯНИЕ ПО СЧЁТУ ===
      double targetSpeed;
      _obstacleSpacing = 2.5; // Базовое

      if (_score < 5) {
        targetSpeed = 0.9; // Очень медленно
        _obstacleSpacing = 3.0;
      } else if (_score < 10) {
        targetSpeed = 1;
        _obstacleSpacing = 2.8;
      } else if (_score < 20) {
        targetSpeed = 1;
        _obstacleSpacing = 2.6;
      } else if (_score < 30) {
        targetSpeed = 1;
        _obstacleSpacing = 2.4;
      } else if (_score < 50) {
        targetSpeed = 1.2;
        _obstacleSpacing = 2.2;
      } else {
        targetSpeed = _maxSpeed;
        _obstacleSpacing = 2.0;
      }

// Плавное изменение скорости
      _currentSpeed += (targetSpeed - _currentSpeed) * 0.02;

      // Плавное приближение (lerp)
      _currentSpeed += (targetSpeed - _currentSpeed) * 0.05;

      // === ДВИЖЕНИЕ ПРЕПЯТСТВИЙ ===
      for (var obstacle in _obstacles) {
        obstacle.x -= _currentSpeed / 100;

        if (obstacle.x < -0.1 && !obstacle.passed) {
          obstacle.passed = true;
          _score++;
        }

        if (obstacle.x < -0.3) {
          obstacle.x = _obstacleSpacing;
          obstacle.type = math.Random().nextBool()
              ? ObstacleType.cactus
              : ObstacleType.rock;
          obstacle.passed = false;
        }
      }

      _checkCollisions();
    });
  }

  void _checkCollisions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final dinoSize = 60.0;
    final dinoScreenX = 100.0;
    final dinoScreenY = MediaQuery.of(context).size.height - 150 - _dinoY;

    for (var obstacle in _obstacles) {
      final obstacleScreenX = obstacle.x * screenWidth;
      final obstacleWidth = obstacle.type == ObstacleType.cactus ? 40.0 : 50.0;
      final obstacleHeight = obstacle.type == ObstacleType.cactus ? 60.0 : 40.0;
      final obstacleScreenY = MediaQuery.of(context).size.height - 150;

      final hitboxMargin = 20.0;

      final dinoLeft = dinoScreenX + hitboxMargin;
      final dinoRight = dinoScreenX + dinoSize - hitboxMargin;
      final dinoTop = dinoScreenY + hitboxMargin;
      final dinoBottom = dinoScreenY + dinoSize - hitboxMargin;

      final obstacleLeft = obstacleScreenX;
      final obstacleRight = obstacleScreenX + obstacleWidth;
      final obstacleTop = obstacleScreenY;
      final obstacleBottom = obstacleScreenY + obstacleHeight;

      if (dinoRight > obstacleLeft &&
          dinoLeft < obstacleRight &&
          dinoBottom > obstacleTop &&
          dinoTop < obstacleBottom) {
        _endGame();
        return;
      }
    }
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
    });
    _gameController.stop();
  }

  void _resetGame() {
    setState(() {
      _gameStarted = false;
      _gameOver = false;
      _score = 0;
      _dinoY = _groundLevel;
      _dinoVelocity = 0;
      _isJumping = false;
      _currentSpeed = _initialSpeed; // ← Сброс
    });
    _initObstacles();
  }

  @override
  void dispose() {
    _gameController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _jump,
      child: Container(
        key: const ValueKey('game'),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)],
          ),
        ),
        child: Stack(
          children: [
            ..._buildClouds(),

            // Земля
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8B7355), Color(0xFF6B5345)],
                  ),
                ),
                child: Column(
                  children: [
                    Container(height: 4, color: Color(0xFF4A3728)),
                    Expanded(
                      child: CustomPaint(
                        painter: _GroundPatternPainter(),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Динозавр
            Positioned(
              left: 100,
              bottom: 150 + _dinoY, // ← Ровно на земле
              child: RotationTransition(
                turns: _rotateController,
                child: Image.asset(
                  'assets/icons/playstore.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Препятствия
            ..._obstacles.map((obstacle) => _buildObstacle(obstacle)),

            // Счёт
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFB800), size: 24),
                      SizedBox(width: 8),
                      Text('$_score',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2E52),
                              fontFamily: 'Gilroy')),
                    ],
                  ),
                ),
              ),
            ),

            // Game Over
            if (_gameOver)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(40),
                    margin: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: Offset(0, 15))
                        ]),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Color(0xFF4A90E2),
                                Color(0xFF006FFD)
                              ]),
                              shape: BoxShape.circle),
                          child: Icon(
                              _score >= 20
                                  ? Icons.emoji_events
                                  : _score >= 10
                                      ? Icons.sentiment_very_satisfied
                                      : Icons.sentiment_satisfied,
                              color: Colors.white,
                              size: 45),
                        ),
                        SizedBox(height: 24),
                        Text(
                          _score >= 30
                              ? 'Легенда!'
                              : _score >= 20
                                  ? 'Отлично!'
                                  : _score >= 10
                                      ? 'Хорошо!'
                                      : _score >= 5
                                          ? 'Неплохо!'
                                          : 'Попробуйте еще!',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2E52),
                              fontFamily: 'Gilroy'),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                color: Color(0xFFFFB800), size: 28),
                            SizedBox(width: 8),
                            Text('Счет: $_score',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E2E52),
                                    fontFamily: 'Golos')),
                          ],
                        ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _jump,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF006FFD),
                            padding: EdgeInsets.symmetric(
                                horizontal: 48, vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text('Играть снова',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Gilroy')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Кнопка закрытия
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ]),
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close_rounded,
                      color: Color(0xFF1E2E52), size: 28),
                ),
              ),
            ),

            // Инструкция
            if (!_gameStarted && !_gameOver)
              Center(
                child: Container(
                  padding: EdgeInsets.all(32),
                  margin: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: Offset(0, 15))
                      ]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Color(0xFF4A90E2), Color(0xFF006FFD)]),
                            shape: BoxShape.circle),
                        child: Icon(Icons.touch_app,
                            color: Colors.white, size: 48),
                      ),
                      SizedBox(height: 24),
                      Text('shamCRM Runner',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2E52),
                              fontFamily: 'Gilroy')),
                      SizedBox(height: 16),
                      Text(
                          'Нажимайте на экран,\nчтобы прыгать!\n\nИзбегайте препятствий',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E2E52).withOpacity(0.7),
                              fontFamily: 'Golos',
                              height: 1.6)),
                      SizedBox(height: 24),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Нажмите для начала',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006FFD),
                                fontFamily: 'Golos')),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildClouds() {
    return [
      Positioned(top: 80, left: 60, child: _buildCloud(0.8)),
      Positioned(top: 150, right: 100, child: _buildCloud(0.6)),
      Positioned(top: 220, left: 200, child: _buildCloud(0.7)),
    ];
  }

  Widget _buildCloud(double opacity) {
    return Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(25)));
  }

  Widget _buildObstacle(Obstacle obstacle) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Positioned(
      left: obstacle.x * screenWidth,
      bottom: 150, // ← Ровно на земле
      child:
          obstacle.type == ObstacleType.cactus ? _buildCactus() : _buildRock(),
    );
  }

  Widget _buildCactus() {
    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
          color: Color(0xFF2D5016),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4))
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
              width: 8,
              height: 15,
              decoration: BoxDecoration(
                  color: Color(0xFF3D6B1F),
                  borderRadius: BorderRadius.circular(4))),
          Container(
              width: 8,
              height: 15,
              decoration: BoxDecoration(
                  color: Color(0xFF3D6B1F),
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildRock() {
    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(
          color: Color(0xFF808080),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4))
          ]),
    );
  }
}

enum ObstacleType { cactus, rock }

class Obstacle {
  double x;
  ObstacleType type;
  bool passed;

  Obstacle({required this.x, required this.type, this.passed = false});
}

// ============================================================================
// PAINTERS
// ============================================================================

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => false;
}

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 20, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GeometricPatternPainter oldDelegate) => false;
}

class _GroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF5A4235).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_GroundPatternPainter oldDelegate) => false;
}
