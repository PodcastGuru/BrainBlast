// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/game.dart';
// import '../services/api_service.dart';
// import 'home_screen.dart';

// class ResultsScreen extends StatefulWidget {
//   final Game game;
//   final String gameCode;

//   const ResultsScreen({
//     required this.game,
//     required this.gameCode,
//   });

//   @override
//   _ResultsScreenState createState() => _ResultsScreenState();
// }

// class _ResultsScreenState extends State<ResultsScreen> {
//   bool _isSavingStats = false;
//   bool _statsSubmitted = false;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     // Optionally update game stats on the server
//     _updateGameStats();
//   }

//   Future<void> _updateGameStats() async {
//     try {
//       setState(() {
//         _isSavingStats = true;
//       });
      
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       final result = await apiService.authPost('games/${widget.game.id}/complete', {
//         'gameCode': widget.gameCode,
//       });
      
//       setState(() {
//         _isSavingStats = false;
//         _statsSubmitted = result['success'] == true;
//         if (!_statsSubmitted) {
//           _errorMessage = result['message'];
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _isSavingStats = false;
//         _errorMessage = 'Error updating stats: ${e.toString()}';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isWinner = widget.game.winner == 'player1';
//     final isDraw = widget.game.winner == null && widget.game.status == 'completed';
    
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Game Results'),
//         automaticallyImplyLeading: false,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _buildResultHeader(isWinner, isDraw),
//               SizedBox(height: 30),
//               _buildScoreCard(),
//               SizedBox(height: 20),
//               _buildPlayerStats(),
//               SizedBox(height: 30),
//               _buildRoundsSummary(),
//               SizedBox(height: 40),
//               _buildActionButtons(context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResultHeader(bool isWinner, bool isDraw) {
//     IconData iconData;
//     Color iconColor;
//     String resultText;
    
//     if (isDraw) {
//       iconData = Icons.equalizer;
//       iconColor = Colors.blue;
//       resultText = 'Game Tied!';
//     } else if (isWinner) {
//       iconData = Icons.emoji_events;
//       iconColor = Colors.amber;
//       resultText = 'You Won!';
//     } else {
//       iconData = Icons.sentiment_dissatisfied;
//       iconColor = Colors.red;
//       resultText = 'You Lost';
//     }
    
//     return Column(
//       children: [
//         Icon(
//           iconData,
//           size: 80,
//           color: iconColor,
//         ),
//         SizedBox(height: 16),
//         Text(
//           resultText,
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//             color: iconColor,
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           'Game Code: ${widget.gameCode}',
//           style: TextStyle(fontSize: 16),
//         ),
//         if (_isSavingStats)
//           Padding(
//             padding: const EdgeInsets.only(top: 16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//                 SizedBox(width: 10),
//                 Text('Saving results...'),
//               ],
//             ),
//           ),
//         if (_statsSubmitted)
//           Padding(
//             padding: const EdgeInsets.only(top: 16.0),
//             child: Text(
//               'Results saved to your profile',
//               style: TextStyle(color: Colors.green),
//             ),
//           ),
//         if (_errorMessage != null)
//           Padding(
//             padding: const EdgeInsets.only(top: 16.0),
//             child: Text(
//               _errorMessage!,
//               style: TextStyle(color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildScoreCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             Column(
//               children: [
//                 Text('You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 SizedBox(height: 8),
//                 Text(
//                   widget.game.player1Score.toString(),
//                   style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             Container(
//               height: 60,
//               width: 1,
//               color: Colors.grey[300],
//             ),
//             Column(
//               children: [
//                 Text('Opponent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 SizedBox(height: 8),
//                 Text(
//                   widget.game.player2Score.toString(),
//                   style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPlayerStats() {
//     // Calculate stats
//     int totalQuestions = widget.game.rounds.length;
//     int correctAnswers = widget.game.rounds
//         .where((round) => round.player1Answer?.isCorrect == true)
//         .length;
    
//     double correctPercentage = totalQuestions > 0 
//         ? (correctAnswers / totalQuestions) * 100 
//         : 0;
    
//     double avgTimeMs = widget.game.rounds
//         .where((round) => round.player1Answer != null)
//         .map((round) => round.player1Answer!.timeElapsed)
//         .fold(0, (sum, time) => sum + time) / 
//         (widget.game.rounds.where((round) => round.player1Answer != null).length);
    
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Your Performance',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             _buildStatRow(
//               'Questions Answered', 
//               '${widget.game.rounds.where((r) => r.player1Answer != null).length}/$totalQuestions'
//             ),
//             _buildStatRow(
//               'Correct Answers', 
//               '$correctAnswers/$totalQuestions (${correctPercentage.toStringAsFixed(0)}%)'
//             ),
//             _buildStatRow(
//               'Average Time', 
//               '${(avgTimeMs / 1000).toStringAsFixed(2)} seconds'
//             ),
//             _buildStatRow(
//               'Fastest Answer', 
//               '${(widget.game.rounds
//                 .where((round) => round.player1Answer != null)
//                 .map((round) => round.player1Answer!.timeElapsed)
//                 .reduce((min, time) => min < time ? min : time) / 1000).toStringAsFixed(2)} seconds'
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(fontSize: 16)),
//           Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildRoundsSummary() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Round Summary',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             ...widget.game.rounds.map((round) => _buildRoundRow(round)).toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRoundRow(Round round) {
//     final player1Answer = round.player1Answer;
//     final player2Answer = round.player2Answer;
    
//     IconData resultIcon;
//     Color resultColor;
    
//     if (round.winner == null) {
//       resultIcon = Icons.remove;
//       resultColor = Colors.grey;
//     } else if (round.winner == 'player1') {
//       resultIcon = Icons.check_circle;
//       resultColor = Colors.green;
//     } else {
//       resultIcon = Icons.cancel;
//       resultColor = Colors.red;
//     }
    
//     return Container(
//       decoration: BoxDecoration(
//         border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
//       ),
//       padding: EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         children: [
//           Icon(resultIcon, color: resultColor, size: 20),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Round ${round.roundNumber}',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 if (player1Answer != null) 
//                   Text(
//                     'Your answer: ${player1Answer.value} (${player1Answer.isCorrect ? 'Correct' : 'Incorrect'})',
//                     style: TextStyle(
//                       color: player1Answer.isCorrect ? Colors.green : Colors.red,
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text('Time: ${player1Answer != null ? (player1Answer.timeElapsed / 1000).toStringAsFixed(2) : 'N/A'} sec'),
//               if (player2Answer != null) 
//                 Text(
//                   'Opponent: ${(player2Answer.timeElapsed / 1000).toStringAsFixed(2)} sec',
//                   style: TextStyle(fontSize: 12),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         ElevatedButton.icon(
//           icon: Icon(Icons.home),
//           label: Text('Back to Home'),
//           style: ElevatedButton.styleFrom(
//             padding: EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           onPressed: () {
//             Navigator.of(context).pushAndRemoveUntil(
//               MaterialPageRoute(builder: (context) => HomeScreen()),
//               (route) => false,
//             );
//           },
//         ),
//         SizedBox(height: 12),
//         OutlinedButton.icon(
//           icon: Icon(Icons.share),
//           label: Text('Share Results'),
//           style: OutlinedButton.styleFrom(
//             padding: EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           onPressed: () {
//             // Implement share functionality
//             final score = 'SAT Math Challenge: I ${widget.game.winner == 'player1' ? 'won' : 'lost'} ${widget.game.player1Score}-${widget.game.player2Score}!';
//             // In a real app, you would use a sharing plugin here
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Sharing: $score')),
//             );
//           },
//         ),
//         SizedBox(height: 12),
//         TextButton.icon(
//           icon: Icon(Icons.replay),
//           label: Text('Play Again'),
//           style: TextButton.styleFrom(
//             padding: EdgeInsets.symmetric(vertical: 16),
//           ),
//           onPressed: () {
//             // Navigate to create game screen
//             Navigator.of(context).pushNamedAndRemoveUntil('/create_game', (route) => false);
//           },
//         ),
//       ],
//     );
//   }
// }