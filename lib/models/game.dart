import 'dart:convert';
import 'package:http/http.dart' as http;

class Game {
  final int id;
  final String player1;
  final String player2;
  final int position;
  final int status;
  final int turn;
  final List<String> ships;
  final List<String> wrecks;
  final List<String> shots;
  final List<String> sunk;

  Game({
    required this.id,
    required this.player1,
    required this.player2,
    required this.position,
    required this.status,
    required this.turn,
    this.ships = const [],
    this.wrecks = const [],
    this.shots = const [],
    this.sunk = const [],
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      player1: json['player1'] ?? '',
      player2: json['player2'] ?? '',
      position: json['position'],
      status: json['status'],
      turn: json['turn'] ?? 0,
      ships: (json['ships'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      wrecks: (json['wrecks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      shots: (json['shots'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sunk: (json['sunk'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  bool get isMatchmaking => status == 0;
  bool get isWonByPlayer1 => status == 1;
  bool get isWonByPlayer2 => status == 2;
  bool get isActive => status == 3;
  bool get isMyTurn => isActive && turn == position;
  bool get isCompleted => isWonByPlayer1 || isWonByPlayer2;

  static const String baseUrl = 'https://battleships-app.onrender.com';

  static Future<List<Game>> getGames(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/games'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['games'] as List)
          .map((game) => Game.fromJson(game))
          .toList();
    } else {
      throw Exception('Failed to load games');
    }
  }

  static Future<Game> getGameDetails(String accessToken, int gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/games/$gameId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return Game.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load game details');
    }
  }

  static Future<Map<String, dynamic>> createGame(
    String accessToken,
    List<String> ships, {
    String? aiType,
  }) async {
    final Map<String, dynamic> body = {'ships': ships};
    if (aiType != null) {
      body['ai'] = aiType;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/games'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create game');
    }
  }

  static Future<Map<String, dynamic>> playShot(
    String accessToken,
    int gameId,
    String shot,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/games/$gameId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'shot': shot}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to play shot');
    }
  }

  static Future<void> deleteGame(String accessToken, int gameId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/games/$gameId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete game');
    }
  }
} 