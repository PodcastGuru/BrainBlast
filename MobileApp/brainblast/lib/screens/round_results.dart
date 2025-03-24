// import 'package:flutter/material.dart';
// import 'package:flutter_math_fork/flutter_math.dart';
// import '../models/game.dart'; // Import your game models

// class RoundResultsWidget extends StatelessWidget {
//   final Round round;
//   final bool isWinner;

//   const RoundResultsWidget({
//     Key? key,
//     required this.round,
//     required this.isWinner,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (round == null) return SizedBox.shrink();

//     final yourAnswer = round.player1Answer;
//     final opponentAnswer = round.player2Answer;
//     final question = round.question;

//     // Determine the result type for styling
//     final String resultType;
//     if (isWinner) {
//       resultType = 'winner';
//     } else if (yourAnswer?.isCorrect == opponentAnswer?.isCorrect) {
//       resultType = 'tie';
//     } else {
//       resultType = 'loser';
//     }

//     // Choose emoji based on result
//     final String resultEmoji;
//     if (isWinner) {
//       resultEmoji = '🏆';
//     } else if (yourAnswer?.isCorrect == opponentAnswer?.isCorrect) {
//       resultEmoji = '🤝';
//     } else {
//       resultEmoji = '❌';
//     }

//     // Set colors based on result type
//     final Color backgroundColor;
//     final Color headerColor;
    
//     switch (resultType) {
//       case 'winner':
//         backgroundColor = Colors.green.shade50;
//         headerColor = Colors.green.shade700;
//         break;
//       case 'tie':
//         backgroundColor = Colors.blue.shade50;
//         headerColor = Colors.blue.shade700;
//         break;
//       case 'loser':
//         backgroundColor = Colors.red.shade50;
//         headerColor = Colors.red.shade700;
//         break;
//       default:
//         backgroundColor = Colors.grey.shade100;
//         headerColor = Colors.grey.shade700;
//     }

//     return Container(
//       width: double.infinity,
//       margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 5,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Result header
//           Container(
//             padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             decoration: BoxDecoration(
//               color: headerColor,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Round ${round.roundNumber} Results',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   resultEmoji,
//                   style: TextStyle(fontSize: 24),
//                 ),
//               ],
//             ),
//           ),
          
//           // Results grid
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 // Your answer column
//                 Expanded(
//                   child: _buildAnswerColumn(
//                     'Your Answer',
//                     yourAnswer?.value ?? 'N/A',
//                     yourAnswer?.isCorrect ?? false,
//                     yourAnswer?.timeElapsed ?? 0,
//                   ),
//                 ),
                
//                 // VS divider
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12),
//                   child: Text(
//                     'VS',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                 ),
                
//                 // Opponent's answer column
//                 Expanded(
//                   child: _buildAnswerColumn(
//                     'Opponent\'s Answer',
//                     opponentAnswer?.value ?? 'N/A',
//                     opponentAnswer?.isCorrect ?? false,
//                     opponentAnswer?.timeElapsed ?? 0,
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Correct answer section
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(12),
//                 bottomRight: Radius.circular(12),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Correct Answer:',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.green.shade200),
//                   ),
//                   child: Center(
//                     child: question.correctAnswer.contains(r'$') || 
//                            question.correctAnswer.contains('\\')
//                       ? Math.tex(
//                           question.correctAnswer,
//                           textStyle: TextStyle(fontSize: 18),
//                         )
//                       : Text(
//                           question.correctAnswer,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnswerColumn(String title, String answer, bool isCorrect, int timeElapsed) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         SizedBox(height: 8),
//         Container(
//           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//           decoration: BoxDecoration(
//             color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: isCorrect ? Colors.green : Colors.red,
//               width: 1.5,
//             ),
//           ),
//           child: Center(
//             child: Text(
//               answer,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
//               ),
//             ),
//           ),
//         ),
//         SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.timer,
//               size: 14,
//               color: Colors.grey.shade600,
//             ),
//             SizedBox(width: 4),
//             Text(
//               timeElapsed != 0
//                   ? '${(timeElapsed / 1000).toStringAsFixed(2)}s'
//                   : 'N/A',
//               style: TextStyle(
//                 color: Colors.grey.shade700,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }