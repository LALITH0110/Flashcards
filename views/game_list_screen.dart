import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/user.dart';
import '../utils/auth_service.dart';
import 'game_play_screen.dart';
import 'login_screen.dart';
import 'ship_placement_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  List<Game> _games = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;  // New flag for initial loading only
  bool _showCompleted = false;
  bool _isSearchingForGame = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (_isSearchingForGame) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          _loadGames(isRefresh: true);
        }
      });
    }
  }

  Future<void> _loadGames({bool isRefresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (!isRefresh) {
        _isInitialLoading = true;
      }
      _error = null;
    });

    try {
      final user = await User.getUser();
      if (user == null || user.isTokenExpired) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      }

      final games = await Game.getGames(user.accessToken);
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
          _isInitialLoading = false;
        });

        // Check if we found a match while searching
        if (_isSearchingForGame) {
          final matchedGame = games.firstWhere(
            (game) => !game.isCompleted && game.player2.isNotEmpty,
            orElse: () => Game(
              id: -1,
              player1: '',
              player2: '',
              position: 0,
              status: 0,
              turn: 1,
            ),
          );

          if (matchedGame.id != -1) {
            _isSearchingForGame = false;
            _refreshTimer?.cancel();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GamePlayScreen(game: matchedGame),
              ),
            ).then((result) {
              if (result == true) {
                _loadGames();
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGame(Game game) async {
    try {
      final user = await User.getUser();
      if (user == null || user.isTokenExpired) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      }

      await Game.deleteGame(user.accessToken, game.id);
      _loadGames();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _getGameStatus(Game game) {
    if (game.isMatchmaking) {
      return 'Waiting for opponent...';
    }
    if (game.isWonByPlayer1) {
      return game.position == 1 ? 'You Won! 🎉' : 'You Lost';
    }
    if (game.isWonByPlayer2) {
      return game.position == 2 ? 'You Won! 🎉' : 'You Lost';
    }
    if (game.isMyTurn) {
      return '🎮 Your Turn';
    }
    return 'Opponent\'s Turn';
  }

  Color _getStatusColor(Game game) {
    if (game.isMatchmaking) return Colors.orange;
    if (game.isWonByPlayer1 && game.position == 1) return Colors.green;
    if (game.isWonByPlayer2 && game.position == 2) return Colors.green;
    if (game.isCompleted) return Colors.red;
    if (game.isMyTurn) return Colors.blue;
    return Colors.grey;
  }

  Future<void> _startNewGame(bool isAI) async {
    if (isAI) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShipPlacementScreen(aiType: 'random'),
        ),
      );
      
      if (result == true) {
        setState(() => _showCompleted = false);
        await _loadGames();
      }
    } else {
      // Start searching for human opponent
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShipPlacementScreen(aiType: null),
        ),
      );
      
      if (result == true) {
        setState(() {
          _showCompleted = false;
          _isSearchingForGame = true;
        });
        _startAutoRefresh();
        await _loadGames();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _games.where((game) {
      if (_showCompleted) {
        return game.isCompleted;
      } else {
        return !game.isCompleted;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearchingForGame 
          ? const Text('Searching for opponent...')
          : const Text('Battleships'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadGames(isRefresh: true),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'new_human':
                  if (mounted) {
                    await _startNewGame(false);
                  }
                  break;
                case 'new_ai':
                  if (mounted) {
                    await _startNewGame(true);
                  }
                  break;
                case 'toggle_completed':
                  setState(() => _showCompleted = !_showCompleted);
                  break;
                case 'cancel_search':
                  setState(() {
                    _isSearchingForGame = false;
                    _refreshTimer?.cancel();
                  });
                  break;
                case 'logout':
                  _refreshTimer?.cancel();  // Cancel timer before logout
                  await AuthService.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              if (!_isSearchingForGame) ...[
                const PopupMenuItem(
                  value: 'new_human',
                  child: Text('New Game vs Human'),
                ),
                const PopupMenuItem(
                  value: 'new_ai',
                  child: Text('New Game vs AI'),
                ),
                PopupMenuItem(
                  value: 'toggle_completed',
                  child: Text(_showCompleted ? 'Show Active Games' : 'Show Completed Games'),
                ),
              ],
              if (_isSearchingForGame)
                const PopupMenuItem(
                  value: 'cancel_search',
                  child: Text('Cancel Search'),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Stack(
                  children: [
                    if (_isSearchingForGame)
                      const Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Searching for an opponent...',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Please wait while we find a match',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (filteredGames.isEmpty && !_isSearchingForGame)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showCompleted
                                  ? 'No completed games'
                                  : 'No active games',
                            ),
                            const SizedBox(height: 16),
                            if (!_showCompleted)
                              ElevatedButton(
                                onPressed: () => _startNewGame(false),
                                child: const Text('Start New Game'),
                              ),
                          ],
                        ),
                      )
                    else if (!_isSearchingForGame)
                      ListView.builder(
                        itemCount: filteredGames.length,
                        itemBuilder: (context, index) {
                          final game = filteredGames[index];
                          return Dismissible(
                            key: Key(game.id.toString()),
                            direction: game.isCompleted ? DismissDirection.none : DismissDirection.endToStart,
                            onDismissed: (_) => _deleteGame(game),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              title: Text('Game ${game.id}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (game.player2.isNotEmpty)
                                    Text('${game.player1} vs ${game.player2}')
                                  else
                                    Text(game.player1),
                                  Text(
                                    _getGameStatus(game),
                                    style: TextStyle(
                                      color: _getStatusColor(game),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GamePlayScreen(game: game),
                                  ),
                                );
                                if (result == true) {
                                  _loadGames();
                                }
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
    );
  }
} 