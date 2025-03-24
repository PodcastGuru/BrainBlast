// lib/models/round.dart

class Answer {
  final String value;
  final bool isCorrect;
  final int timeElapsed;

  Answer({
    required this.value,
    required this.isCorrect,
    required this.timeElapsed,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      value: json['value'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      timeElapsed: json['timeElapsed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isCorrect': isCorrect,
      'timeElapsed': timeElapsed,
    };
  }
}

class Round {
  final int roundNumber;
  final String? winner;
  final Answer? player1Answer;
  final Answer? player2Answer;

  Round({
    required this.roundNumber,
    this.winner,
    this.player1Answer,
    this.player2Answer,
  });

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      roundNumber: json['roundNumber'] ?? 0,
      winner: json['winner'],
      player1Answer: json['yourAnswer'] != null && json['yourAnswer'] is Map && json['yourAnswer'].isNotEmpty 
          ? Answer.fromJson(json['yourAnswer'])
          : null,
      player2Answer: json['opponentAnswer'] != null && json['opponentAnswer'] is Map && json['opponentAnswer'].isNotEmpty
          ? Answer.fromJson(json['opponentAnswer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'winner': winner,
      'player1Answer': player1Answer?.toJson(),
      'player2Answer': player2Answer?.toJson(),
    };
  }

  @override
  String toString() {
    return 'Round $roundNumber: Player1=${player1Answer?.value}, Player2=${player2Answer?.value}, Winner=$winner';
  }
}