import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/user.dart';
import 'widgets/game_board.dart';

class ShipPlacementScreen extends StatefulWidget {
  final String? aiType;

  const ShipPlacementScreen({super.key, this.aiType});

  @override
  State<ShipPlacementScreen> createState() => _ShipPlacementScreenState();
}

class _ShipPlacementScreenState extends State<ShipPlacementScreen> {
  final Set<String> _ships = {};
  bool _isLoading = false;

  void _toggleShip(String position) {
    setState(() {
      if (_ships.contains(position)) {
        _ships.remove(position);
      } else if (_ships.length < 5) {
        _ships.add(position);
      }
    });
  }

  Future<void> _startGame() async {
    if (_ships.length != 5) return;

    setState(() => _isLoading = true);

    try {
      final user = await User.getUser();
      if (user == null || user.isTokenExpired) {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
        return;
      }

      await Game.createGame(
        user.accessToken,
        _ships.toList(),
        aiType: widget.aiType,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Your Ships'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Place ${5 - _ships.length} more ships',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GameBoard(
              ships: _ships.toList(),
              isPlacementMode: true,
              onCellTap: _toggleShip,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _ships.length == 5 ? _startGame : null,
                child: const Text('Start Game'),
              ),
          ],
        ),
      ),
    );
  }
} 