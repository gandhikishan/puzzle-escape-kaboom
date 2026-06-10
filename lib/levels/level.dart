/// Pure-Dart data model for a Bombs and Puzzles stage.
///
/// Intentionally free of Flutter/Flame imports so it can be shared by the game
/// runtime, the offline level-generation tool, and unit tests.
library;

/// The eight directions a bomb can travel toward the board edge.
///
/// Cardinal directions launch a bomb straight off an edge; diagonal directions
/// send it toward a corner for extra spectacle. [dx]/[dy] are grid steps where
/// `x` grows to the right and `y` grows downward.
enum BombDirection {
  up(0, -1, 'up'),
  down(0, 1, 'down'),
  left(-1, 0, 'left'),
  right(1, 0, 'right'),
  upLeft(-1, -1, 'upLeft'),
  upRight(1, -1, 'upRight'),
  downLeft(-1, 1, 'downLeft'),
  downRight(1, 1, 'downRight');

  const BombDirection(this.dx, this.dy, this.id);

  final int dx;
  final int dy;
  final String id;

  bool get isDiagonal => dx != 0 && dy != 0;

  /// Angle in radians used to rotate the on-screen arrow. 0 points up.
  double get angle {
    switch (this) {
      case BombDirection.up:
        return 0;
      case BombDirection.upRight:
        return 0.785398; // pi/4
      case BombDirection.right:
        return 1.570796; // pi/2
      case BombDirection.downRight:
        return 2.356194; // 3pi/4
      case BombDirection.down:
        return 3.141593; // pi
      case BombDirection.downLeft:
        return 3.926991; // 5pi/4
      case BombDirection.left:
        return 4.712389; // 3pi/2
      case BombDirection.upLeft:
        return 5.497787; // 7pi/4
    }
  }

  static BombDirection fromId(String id) =>
      BombDirection.values.firstWhere((d) => d.id == id);

  static const cardinals = [up, down, left, right];
  static const diagonals = [upLeft, upRight, downLeft, downRight];
}

/// A single bomb placed on the grid.
///
/// Most bombs travel straight off the board in [direction]. A bomb may instead
/// follow a curved route by supplying [path]: an ordered list of step
/// directions taken from its cell until it leaves the board. When [path] is
/// set, [direction] is the bomb's initial facing (used for the arrow icon).
class Bomb {
  const Bomb({
    required this.x,
    required this.y,
    required this.direction,
    this.path,
  });

  final int x;
  final int y;
  final BombDirection direction;

  /// Ordered movement steps for a curved bomb, or null for a straight bomb.
  final List<BombDirection>? path;

  bool get isCurved => path != null && path!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'd': direction.id,
        if (isCurved) 'p': path!.map((d) => d.id).toList(),
      };

  factory Bomb.fromJson(Map<String, dynamic> json) => Bomb(
        x: json['x'] as int,
        y: json['y'] as int,
        direction: BombDirection.fromId(json['d'] as String),
        path: (json['p'] as List?)
            ?.map((e) => BombDirection.fromId(e as String))
            .toList(),
      );
}

/// An immutable, fully described puzzle stage.
class Level {
  const Level({
    required this.id,
    required this.width,
    required this.height,
    required this.bombs,
    this.lives = 3,
  });

  final int id;
  final int width;
  final int height;
  final List<Bomb> bombs;

  /// Lives granted for this stage (kept on the level so it is tunable later).
  final int lives;

  int get bombCount => bombs.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'w': width,
        'h': height,
        'lives': lives,
        'b': bombs.map((b) => b.toJson()).toList(),
      };

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: json['id'] as int,
        width: json['w'] as int,
        height: json['h'] as int,
        lives: (json['lives'] as int?) ?? 3,
        bombs: (json['b'] as List)
            .map((e) => Bomb.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Stable signature of the layout used to deduplicate generated stages.
  String signature() {
    final parts = bombs.map((b) {
      final route = b.isCurved ? b.path!.map((d) => d.id).join('>') : b.direction.id;
      return '${b.x},${b.y},$route';
    }).toList()
      ..sort();
    return '$width x$height|${parts.join(';')}';
  }
}
