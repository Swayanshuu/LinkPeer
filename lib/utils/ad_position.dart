import 'dart:math';

List<int> generateAdPositions(int postCount) {
  final random = Random();

  final positions = <int>[];

  int current = random.nextInt(1) + 3; // 8-15

  while (current < postCount) {
    positions.add(current);

    current += random.nextInt(1) + 4; // next gap 8-15
  }

  return positions;
}
