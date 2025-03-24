


// models/game.dart

import 'round.dart';

class Player {
  final String? id;
  final String? name;
  final String? type;  // player1 or player2

  Player({
    this.id,
    this.name,
    this.type,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }
}

class Game {
  final String id;
  final String status; // waiting, active, completed
  final String? currentTurn; // player1 or player2
  final int? player1Score;
  final int? player2Score;
  final int? yourScore;
  final int? opponentScore;
  final int currentRound;
  final List<Round> rounds;
  final Player? player;
  final Map<String, dynamic>? currentQuestion;
  final String? winner;

  Game({
    required this.id,
    required this.status,
    this.currentTurn,
    this.player1Score,
    this.player2Score,
    this.yourScore,
    this.opponentScore,
    this.currentRound = 1,
    this.rounds = const [],
    this.player,
    this.currentQuestion,
    this.winner,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Parse rounds from JSON
    List<Round> parsedRounds = [];
    if (json['rounds'] != null && json['rounds'] is List) {
      parsedRounds = (json['rounds'] as List)
          .map((roundJson) => Round.fromJson(roundJson))
          .toList();
    }

    // Parse player info if available
    Player? parsedPlayer;
    if (json['player'] != null) {
      parsedPlayer = Player.fromJson(json['player']);
    }

    return Game(
      id: json['id'] ?? '',
      status: json['status'] ?? 'waiting',
      currentTurn: json['currentTurn'],
      player1Score: json['player1Score'],
      player2Score: json['player2Score'],
      yourScore: json['yourScore'],
      opponentScore: json['opponentScore'],
      currentRound: json['currentRound'] ?? 1,
      rounds: parsedRounds,
      player: parsedPlayer,
      currentQuestion: json['currentQuestion'],
      winner: json['winner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'currentTurn': currentTurn,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'yourScore': yourScore,
      'opponentScore': opponentScore,
      'currentRound': currentRound,
      'rounds': rounds.map((round) => round.toJson()).toList(),
      'player': player?.toJson(),
      'currentQuestion': currentQuestion,
      'winner': winner,
    };
  }
}