import 'package:flutter/material.dart';

class GameBoard extends StatelessWidget {
  final List<String> ships;
  final List<String> hits;
  final List<String> misses;
  final List<String> sunk;
  final bool isPlacementMode;
  final Function(String)? onCellTap;
  final bool showShips;

  const GameBoard({
    super.key,
    this.ships = const [],
    this.hits = const [],
    this.misses = const [],
    this.sunk = const [],
    this.isPlacementMode = false,
    this.onCellTap,
    this.showShips = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Column labels (1-5)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 30), // Space for row labels
            ...List.generate(5, (i) => SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )),
          ],
        ),
        // Game board grid
        ...List.generate(5, (row) {
          final rowLetter = String.fromCharCode(65 + row); // A, B, C, D, E
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row label (A-E)
              SizedBox(
                width: 30,
                child: Center(
                  child: Text(
                    rowLetter,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Grid cells
              ...List.generate(5, (col) {
                final position = '$rowLetter${col + 1}';
                final isShip = ships.contains(position);
                final isHit = hits.contains(position);
                final isMiss = misses.contains(position);
                final isSunk = sunk.contains(position);

                Color cellColor = Colors.blue.shade100;
                if (isPlacementMode && isShip) {
                  cellColor = Colors.grey;
                } else if (isHit) {
                  cellColor = Colors.red;
                } else if (isMiss) {
                  cellColor = Colors.white;
                } else if (showShips && isShip) {
                  cellColor = Colors.grey;
                }

                return GestureDetector(
                  onTap: onCellTap != null ? () => onCellTap!(position) : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: cellColor,
                      border: Border.all(color: Colors.blue),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
} 