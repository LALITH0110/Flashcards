import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/user.dart';
import 'widgets/game_board.dart';

class GamePlayScreen extends StatefulWidget {
  final Game game;

  const GamePlayScreen({super.key, required this.game});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late Game _game;
  bool _isLoading = false;
  bool _isSilentLoading = false;
  String? _error;
  String? _selectedShot;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    // Load game details immediately without waiting
    _loadInitialGameState();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Load initial game state without showing loading indicator
  Future<void> _loadInitialGameState() async {
    try {
      final user = await User.getUser();
      if (user == null || user.isTokenExpired) {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
        return;
      }

      final updatedGame = await Game.getGameDetails(user.accessToken, _game.id);
      if (mounted) {
        setState(() {
          _game = updatedGame;  // Always update on initial load
        });
        _startAutoRefresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    // Always auto-refresh when game is active
    if (_game.isActive) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          _loadGameDetails(silent: true);
        }
      });
    }
  }

  Future<void> _loadGameDetails({bool silent = false}) async {
    if (_isLoading) return;
    if (_isSilentLoading && silent) return;

    setState(() {
      if (silent) {
        _isSilentLoading = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final user = await User.getUser();
      if (user == null || user.isTokenExpired) {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
        return;
      }

      final updatedGame = await Game.getGameDetails(user.accessToken, _game.id);
      if (mounted) {
        setState(() {
          // Always update game state to ensure turns are reflected correctly
          _game = updatedGame;
          _isLoading = false;
          _isSilentLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isSilentLoading = false;
        });
      }
    }
  }

  Future<void> _playShot(String position) async {
    if (!_game.isMyTurn) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _selectedShot = position;
    });

    try {
      final user = await User.getUser();
      if (user == null || user.isTokenExpired) {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
        return;
      }

      final result = await Game.playShot(
        user.accessToken,
        _game.id,
        position,
      );

      if (mounted) {
        if (result['won'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You won! 🎉')),
          );
          Navigator.of(context).pop(true);
        } else {
          // Load game details immediately after shot
          final updatedGame = await Game.getGameDetails(user.accessToken, _game.id);
          setState(() {
            _game = updatedGame;
            _isLoading = false;
          });
          _startAutoRefresh();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shot played! Waiting for opponent...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getGameStatus() {
    if (_game.isMatchmaking) return 'Waiting for opponent...';
    if (_game.isWonByPlayer1) return _game.position == 1 ? 'You Won! 🎉' : 'You Lost';
    if (_game.isWonByPlayer2) return _game.position == 2 ? 'You Won! 🎉' : 'You Lost';
    if (_game.isMyTurn) return '🎮 Your Turn';
    return 'Opponent\'s Turn';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game ${_game.id}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getGameStatus(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _game.isMyTurn ? Colors.blue : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text('Your Board'),
                            const SizedBox(height: 8),
                            GameBoard(
                              ships: _game.ships,
                              hits: _game.wrecks,    // Hits on your ships
                              misses: [],            // Opponent's missed shots (not available in API)
                              sunk: [],              // Your sunk ships (not available in API)
                              showShips: true,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Opponent\'s Board'),
                            const SizedBox(height: 8),
                            GameBoard(
                              hits: _game.sunk,     // Enemy ships you've hit
                              misses: _game.shots,  // Your missed shots
                              onCellTap: _game.isMyTurn ? _playShot : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_selectedShot != null) ...[
                      const SizedBox(height: 16),
                      Text('Selected shot: $_selectedShot'),
                    ],
                  ],
                ),
    );
  }
} 