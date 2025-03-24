import 'package:brainblast/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/game.dart';
import '../models/round.dart';

class GameResultsScreen extends StatelessWidget {
  final Game gameState;
  final Function onPlayAgain;

  const GameResultsScreen({
    super.key,
    required this.gameState,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    // Add defensive null checks
    final yourScore = gameState.yourScore ?? gameState.player1Score ?? 0;
    final opponentScore = gameState.opponentScore ?? gameState.player2Score ?? 0;

    // Determine winner based on scores (now safe from null errors)
    bool? isWinner;
    String resultText;

    if (yourScore > opponentScore) {
      isWinner = true;
      resultText = '🏆 You Won! 🏆';
    } else if (yourScore < opponentScore) {
      isWinner = false;
      resultText = '💔 You Lost 💔';
    } else {
      isWinner = null; // for tie
      resultText = '🤝 It\'s a Tie! 🤝';
    }

    final playerName = 'You';
    final opponentName = 'Opponent';

    // Calculate stats with safeguards
    final rounds = gameState.rounds ?? [];
    print("########################################################");

    final totalRounds = rounds.length;
    print(rounds);
    // Ensure rounds are valid before filtering
    int yourCorrect = 0;
    int opponentCorrect = 0;

    // Calculate average response times only for correct answers with defensive code
    double yourAvgTime = 0;
    double opponentAvgTime = 0;

    if (rounds.isNotEmpty) {
      // Count correct answers
      yourCorrect = rounds.where((r) => r.player1Answer?.isCorrect == true).length;
      opponentCorrect = rounds.where((r) => r.player2Answer?.isCorrect == true).length;

      // Calculate average times
      final yourCorrectAnswers = rounds.where((r) => r.player1Answer?.isCorrect == true).toList();
      final opponentCorrectAnswers = rounds.where((r) => r.player2Answer?.isCorrect == true).toList();

      if (yourCorrectAnswers.isNotEmpty) {
        yourAvgTime = yourCorrectAnswers.fold(0, (sum, r) => sum + (r.player1Answer?.timeElapsed ?? 0)) / 
            yourCorrectAnswers.length / 1000; // Convert to seconds
      }

      if (opponentCorrectAnswers.isNotEmpty) {
        opponentAvgTime = opponentCorrectAnswers.fold(0, (sum, r) => sum + (r.player2Answer?.timeElapsed ?? 0)) / 
            opponentCorrectAnswers.length / 1000; // Convert to seconds
      }
    }

    // Function to safely format time values
    String formatTime(double? time) {
      if (time == null) return '-';
      return '${time.toStringAsFixed(2)}s';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Game Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Result banner
              Container(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isWinner == true 
                      ? Colors.green.shade100 
                      : isWinner == false 
                          ? Colors.red.shade100 
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      resultText,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isWinner == true 
                            ? Colors.green.shade800 
                            : isWinner == false 
                                ? Colors.red.shade800 
                                : Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Final Score: $yourScore - $opponentScore',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Stats container
              _buildStatsSection(
                context, 
                yourCorrect, 
                opponentCorrect, 
                totalRounds, 
                yourAvgTime, 
                opponentAvgTime, 
                rounds,
                playerName,
                opponentName,
                formatTime,
              ),
              
              SizedBox(height: 24),
              
              // Round history
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Round History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      rounds.isNotEmpty
                          ? _buildRoundHistoryTable(rounds, formatTime)
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('No round history available.'),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.replay),
                    label: Text('Play Again'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => onPlayAgain(),
                  ),
                  OutlinedButton.icon(
                    icon: Icon(Icons.dashboard),
                    label: Text('Back to Dashboard'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () =>  Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    int yourCorrect,
    int opponentCorrect,
    int totalRounds,
    double yourAvgTime,
    double opponentAvgTime,
    List<Round> rounds,
    String playerName,
    String opponentName,
    String Function(double?) formatTime,
  ) {
    return Column(
      children: [
        // Correct Answers Stats Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildPieChart(yourCorrect, opponentCorrect, playerName, opponentName),
                ),
                SizedBox(height: 16),
                _buildStatRow(
                  'You',
                  '$yourCorrect of $totalRounds (${totalRounds > 0 ? (yourCorrect / totalRounds * 100).round() : 0}%)',
                  Colors.blue,
                ),
                SizedBox(height: 8),
                _buildStatRow(
                  'Opponent',
                  '$opponentCorrect of $totalRounds (${totalRounds > 0 ? (opponentCorrect / totalRounds * 100).round() : 0}%)',
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Response Times Stats Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Response Times',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildBarChart(rounds, playerName, opponentName),
                ),
                SizedBox(height: 16),
                _buildStatRow(
  'Your Avg Time (correct answers)', 
  formatTime(yourAvgTime), 
  Colors.blue
),
                SizedBox(height: 8),
                _buildStatRow(
                  'Opponent\'s Avg Time (correct answers)',
                  formatTime(opponentAvgTime),
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(int yourCorrect, int opponentCorrect, String playerName, String opponentName) {
    // Handle the case where both values are 0 to avoid empty chart

    print("#############piechart###########################");
    print(yourCorrect);
    print(opponentCorrect);
    if (yourCorrect == 0 && opponentCorrect == 0) {
      return Center(child: Text('No correct answers yet'));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: yourCorrect.toDouble(),
            title: playerName,
            color: Colors.blue.shade400,
            radius: 80,
            titleStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          PieChartSectionData(
            value: opponentCorrect.toDouble(),
            title: opponentName,
            color: Colors.red.shade400,
            radius: 80,
            titleStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
      ),
    );
  }

  Widget _buildBarChart(List<Round> rounds, String playerName, String opponentName) {
    print("#############BarChart###########################");
    print(rounds);
    if (rounds.isEmpty) {
      return Center(child: Text('No data available'));
    }

    // Prepare data for chart
    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[];

    for (int i = 0; i < rounds.length; i++) {
      if (rounds[i].player1Answer != null) {
        spots1.add(FlSpot(
          i.toDouble(),
          rounds[i].player1Answer!.timeElapsed / 1000, // Convert to seconds
        ));
      }
      
      if (rounds[i].player2Answer != null) {
        spots2.add(FlSpot(
          i.toDouble(),
          rounds[i].player2Answer!.timeElapsed / 1000, // Convert to seconds
        ));
      }
    }

    // Find max Y for better scaling
    double maxY = 20.0; // Default
    try {
      for (var round in rounds) {
        final player1Time = round.player1Answer?.timeElapsed ?? 0;
        final player2Time = round.player2Answer?.timeElapsed ?? 0;
        final maxTime = (player1Time > player2Time ? player1Time : player2Time) / 1000;
        if (maxTime > maxY) {
          maxY = maxTime + 5; // Add some margin
        }
      }
    } catch (e) {
      print('Error calculating maxY: $e');
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('0', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12));
                if (value % 5 == 0) return Text('${value.toInt()}s', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12));
                return Text('');
              },
              reservedSize: 30,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final roundNumber = (value.toInt() + 1);
                return Text('R$roundNumber', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 5,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        barGroups: List.generate(rounds.length, (index) {
          final yourTime = rounds[index].player1Answer?.timeElapsed ?? 0;
          final opponentTime = rounds[index].player2Answer?.timeElapsed ?? 0;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: yourTime / 1000, // Convert to seconds
                color: Colors.blue.shade400,
                width: 12,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: opponentTime / 1000, // Convert to seconds
                color: Colors.red.shade400,
                width: 12,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRoundHistoryTable(List<Round> rounds, String Function(double?) formatTime) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Round', style: TextStyle(fontWeight: FontWeight.bold))),
          // DataColumn(label: Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Your Time', style: TextStyle(fontWeight: FontWeight.bold))),
          // DataColumn(label: Text('Opponent\'s Answer', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Opponent\'s Time', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Winner', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: rounds.map((round) {
          final yourAnswer = round.player1Answer;
          final opponentAnswer = round.player2Answer;
          
          return DataRow(
            cells: [
              DataCell(Text('${round.roundNumber}')),
              // DataCell(
              //   Container(
              //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: yourAnswer?.isCorrect == true ? Colors.green.shade50 : Colors.red.shade50,
              //       borderRadius: BorderRadius.circular(4),
              //     ),
              //     child: Text(
              //       yourAnswer?.value ?? '-',
              //       style: TextStyle(
              //         color: yourAnswer?.isCorrect == true ? Colors.green.shade800 : Colors.red.shade800,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //   ),
              // ),
              DataCell(Text(formatTime(yourAnswer?.timeElapsed != null ? yourAnswer!.timeElapsed / 1000 : null))),
              // DataCell(
              //   Container(
              //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: opponentAnswer?.isCorrect == true ? Colors.green.shade50 : Colors.red.shade50,
              //       borderRadius: BorderRadius.circular(4),
              //     ),
              //     child: Text(
              //       opponentAnswer?.value ?? '-',
              //       style: TextStyle(
              //         color: opponentAnswer?.isCorrect == true ? Colors.green.shade800 : Colors.red.shade800,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //   ),
              // ),
              DataCell(Text(formatTime(opponentAnswer?.timeElapsed != null ? opponentAnswer!.timeElapsed / 1000 : null))),
              DataCell(
  Text(
    round.winner == 'player1' ? 'You' :
    round.winner == 'player2' ? 'Opponent' :
    round.winner == 'tie' ? 'Tie' :
    round.winner == 'you' ? 'Win' :
    round.winner == 'opponent' ? 'Loss' : '-',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
)

            ],
          );
        }).toList(),
      ),
    );
  }
}