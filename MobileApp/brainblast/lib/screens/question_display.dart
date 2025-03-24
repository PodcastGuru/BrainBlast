// import 'package:flutter/material.dart';
// import 'package:flutter_math_fork/flutter_math.dart';
// import 'dart:async';

// class QuestionDisplayWidget extends StatefulWidget {
//   final Map<String, dynamic> question;
//   final Function(String, double) onSubmit;

//   const QuestionDisplayWidget({
//     super.key,
//     required this.question,
//     required this.onSubmit,
//   });

//   @override
//   _QuestionDisplayWidgetState createState() => _QuestionDisplayWidgetState();
// }

// class _QuestionDisplayWidgetState extends State<QuestionDisplayWidget> {
//   String _answer = '';
//   double _timer = 0.0;
//   bool _submitted = false;
//   Timer? _timerRef;
//   late DateTime _startTime;

//   @override
//   void initState() {
//     super.initState();
//     _startTime = DateTime.now();
    
//     // Start timer
//     _timerRef = Timer.periodic(Duration(milliseconds: 50), (timer) {
//       setState(() {
//         _timer = DateTime.now().difference(_startTime).inMilliseconds / 1000;
//       });
//     });
    
//     // Debug log
//     print("Question received in QuestionDisplay: ${widget.question}");
//   }

//   @override
//   void dispose() {
//     _timerRef?.cancel();
//     super.dispose();
//   }

//   void _handleSubmit() {
//     if (_submitted) return;
    
//     // Stop timer
//     _timerRef?.cancel();
    
//     // Submit answer to parent component
//     widget.onSubmit(_answer, _timer);
    
//     setState(() {
//       _submitted = true;
//     });
//   }

//   // Format timer as MM:SS.ss
//   String _formatTime(double seconds) {
//     final mins = (seconds ~/ 60).toString().padLeft(2, '0');
//     final secs = (seconds.floor() % 60).toString().padLeft(2, '0');
//     final ms = ((seconds % 1) * 100).floor().toString().padLeft(2, '0');
//     return "$mins:$secs.$ms";
//   }

//   // Handle direct option selection for multiple choice
//   void _handleOptionSelect(String value) {
//     if (_submitted) return;
//     setState(() {
//       _answer = value;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Timer display
//           Container(
//             padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//             decoration: BoxDecoration(
//               color: Colors.blue.shade100,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   _formatTime(_timer),
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'monospace',
//                   ),
//                 ),
//                 Text(
//                   'Time Elapsed',
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
//                 ),
//               ],
//             ),
//           ),
          
//           SizedBox(height: 20),
          
//           // Question text
//           Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: widget.question['text'].toString().contains(r'$') || 
//                     widget.question['text'].toString().contains('\\')
//                 ? Math.tex(
//                     widget.question['text'].toString(),
//                     textStyle: TextStyle(fontSize: 18),
//                   )
//                 : Text(
//                     widget.question['text'].toString(),
//                     style: TextStyle(fontSize: 18),
//                   ),
//             ),
//           ),
          
//           // Question image if available
//           if (widget.question['imageUrl'] != null)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   widget.question['imageUrl'],
//                   height: 200,
//                   fit: BoxFit.contain,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container(
//                       height: 100,
//                       color: Colors.grey.shade200,
//                       child: Center(
//                         child: Text('Image failed to load'),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
          
//           SizedBox(height: 20),
          
//           // Answer section
//           Expanded(
//             child: _buildAnswerSection(),
//           ),
          
//           // Submit button
//           ElevatedButton(
//             onPressed: (_answer.isEmpty || _submitted) ? null : _handleSubmit,
//             style: ElevatedButton.styleFrom(
//               padding: EdgeInsets.symmetric(vertical: 16),
//               backgroundColor: _submitted ? Colors.green : null,
//             ),
//             child: Text(
//               _submitted ? 'Answer Submitted' : 'Submit Answer',
//               style: TextStyle(fontSize: 18),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnswerSection() {
//     // Handle multiple-choice questions
//     if (widget.question['type'] == 'multiple-choice' && 
//         widget.question['options'] != null &&
//         widget.question['options'] is List) {
      
//       // Debug output for options
//       print("Multiple choice options: ${widget.question['options']}");
      
//       final options = List<dynamic>.from(widget.question['options']);
      
//       // Handle empty options array
//       if (options.isEmpty) {
//         return Container(
//           padding: EdgeInsets.all(16),
//           color: Colors.red.shade50,
//           child: Text(
//             'No options available for this question. Please refresh or contact support.',
//             style: TextStyle(color: Colors.red),
//             textAlign: TextAlign.center,
//           ),
//         );
//       }
      
//       // Render options
//       return ListView.builder(
//         shrinkWrap: true,
//         itemCount: options.length,
//         itemBuilder: (context, index) {
//           final option = options[index];
//           final value = option['value'] ?? '';
//           final label = option['label'] ?? String.fromCharCode(65 + index); // A, B, C, D...
//           final text = option['text'] ?? '';
//           final isSelected = _answer == value;
          
//           return Card(
//             elevation: isSelected ? 4 : 1,
//             margin: EdgeInsets.symmetric(vertical: 8),
//             color: isSelected ? Colors.blue.shade100 : null,
//             child: InkWell(
//               onTap: _submitted ? null : () => _handleOptionSelect(value),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 30,
//                       height: 30,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: isSelected ? Colors.blue : Colors.grey.shade200,
//                         border: Border.all(
//                           color: isSelected ? Colors.blue.shade700 : Colors.grey,
//                           width: 2,
//                         ),
//                       ),
//                       child: isSelected 
//                         ? Icon(Icons.check, color: Colors.white, size: 18) 
//                         : null,
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: RichText(
//                         text: TextSpan(
//                           style: TextStyle(color: Colors.black, fontSize: 16),
//                           children: [
//                             TextSpan(
//                               text: '$label: ',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             TextSpan(text: text),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     } 
//     // Fallback for multiple-choice with missing options
//     else if (widget.question['type'] == 'multiple-choice') {
//       return Container(
//         padding: EdgeInsets.all(16),
//         color: Colors.red.shade50,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Question options are missing. Please refresh the page or contact support.',
//               style: TextStyle(color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 16),
//             Container(
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 widget.question.toString(),
//                 style: TextStyle(fontFamily: 'monospace', fontSize: 12),
//               ),
//             ),
//           ],
//         ),
//       );
//     } 
//     // Text/numeric answer input for non multiple-choice questions
//     else {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16.0),
//         child: TextField(
//           enabled: !_submitted,
//           onChanged: (value) {
//             setState(() {
//               _answer = value;
//             });
//           },
//           autofocus: true,
//           decoration: InputDecoration(
//             labelText: 'Your Answer',
//             hintText: 'Enter your answer...',
//             border: OutlineInputBorder(),
//             filled: _submitted,
//             fillColor: _submitted ? Colors.grey.shade200 : null,
//           ),
//           style: TextStyle(fontSize: 18),
//         ),
//       );
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'dart:async';

class QuestionDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(String, double) onSubmit;

  const QuestionDisplayWidget({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  _QuestionDisplayWidgetState createState() => _QuestionDisplayWidgetState();
}

class _QuestionDisplayWidgetState extends State<QuestionDisplayWidget> {
  String _answer = '';
  double _timer = 0.0;
  bool _submitted = false;
  Timer? _timerRef;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    // Start timer
    _timerRef = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        _timer = DateTime.now().difference(_startTime).inMilliseconds / 1000;
      });
    });
    
    // Debug log
    print("Question received in QuestionDisplay: ${widget.question}");
  }

  @override
  void dispose() {
    _timerRef?.cancel();
    super.dispose();
  }

  void _handleSubmit() {
    if (_submitted) return;
    
    // Stop timer
    _timerRef?.cancel();
    
    // Submit answer to parent component
    widget.onSubmit(_answer, _timer);
    
    setState(() {
      _submitted = true;
    });
  }

  // Format timer as MM:SS.ss
  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.floor() % 60).toString().padLeft(2, '0');
    final ms = ((seconds % 1) * 100).floor().toString().padLeft(2, '0');
    return "$mins:$secs.$ms";
  }

  // Handle direct option selection for multiple choice
  void _handleOptionSelect(String value) {
    if (_submitted) return;
    setState(() {
      _answer = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive adjustments
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 900;
    final isLargeScreen = screenSize.width >= 900;
    
    // Adjust font sizes based on screen size
    final questionFontSize = isSmallScreen ? 16.0 : isMediumScreen ? 18.0 : 20.0;
    final timerFontSize = isSmallScreen ? 22.0 : isMediumScreen ? 24.0 : 28.0;
    final optionFontSize = isSmallScreen ? 14.0 : isMediumScreen ? 16.0 : 18.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timer and difficulty row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer display
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_timer),
                            style: TextStyle(
                              fontSize: timerFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: _timer > 30 ? Colors.red : Colors.black87,
                            ),
                          ),
                          Text(
                            'Time Elapsed',
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  // Difficulty badge
                  if (widget.question['difficulty'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(widget.question['difficulty']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.question['difficulty'].toString().toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    
                  // Subject badge  
                  if (widget.question['subject'] != null)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.question['subject'].toString().toUpperCase(),
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Question text
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.blue.shade50],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: widget.question['text'].toString().contains(r'$') || 
                        widget.question['text'].toString().contains('\\')
                    ? Math.tex(
                        widget.question['text'].toString(),
                        textStyle: TextStyle(fontSize: questionFontSize),
                      )
                    : Text(
                        widget.question['text'].toString(),
                        style: TextStyle(
                          fontSize: questionFontSize,
                          height: 1.4,
                        ),
                      ),
                ),
              ),
              
              // Question image if available
              if (widget.question['imageUrl'] != null && widget.question['imageUrl'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.question['imageUrl'],
                      height: isSmallScreen ? 150 : 200,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: isSmallScreen ? 150 : 200,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: isSmallScreen ? 100 : 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Image failed to load'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              SizedBox(height: isSmallScreen ? 12 : 20),
              
              // Answer section
              Expanded(
                child: _buildAnswerSection(optionFontSize, isSmallScreen),
              ),
              
              // Submit button
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 56,
                margin: EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: _answer.isEmpty || _submitted 
                    ? [] 
                    : [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                ),
                child: ElevatedButton(
                  onPressed: (_answer.isEmpty || _submitted) ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    elevation: _answer.isEmpty || _submitted ? 0 : 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _submitted 
                      ? Colors.green 
                      : _answer.isEmpty ? Colors.grey.shade300 : Colors.blue,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _submitted 
                        ? Icon(Icons.check_circle, color: Colors.white)
                        : Icon(
                            _answer.isEmpty ? Icons.edit : Icons.send,
                            color: _answer.isEmpty ? Colors.grey : Colors.white,
                          ),
                      SizedBox(width: 8),
                      Text(
                        _submitted ? 'Answer Submitted' : 'Submit Answer',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: _answer.isEmpty && !_submitted ? Colors.grey : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    if (difficulty == null) return Colors.grey;
    
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'hard':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  Widget _buildAnswerSection(double fontSize, bool isSmallScreen) {
    // Handle multiple-choice questions
    if (widget.question['type'] == 'multiple-choice' && 
        widget.question['options'] != null &&
        widget.question['options'] is List) {
      
      final options = List<dynamic>.from(widget.question['options']);
      
      // Handle empty options array
      if (options.isEmpty) {
        return _buildErrorContainer('No options available for this question. Please refresh or contact support.');
      }
      
      // Render options
      return ListView.builder(
        shrinkWrap: true,
        physics: options.length <= 4 ? NeverScrollableScrollPhysics() : null,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final value = option['value'] ?? '';
          final label = option['label'] ?? String.fromCharCode(65 + index); // A, B, C, D...
          final text = option['text'] ?? '';
          final isSelected = _answer == value;
          
          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ] : [],
            ),
            child: Card(
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                  width: 2,
                ),
              ),
              margin: EdgeInsets.zero,
              color: isSelected ? Colors.blue.shade50 : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _submitted ? null : () => _handleOptionSelect(value),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                    horizontal: isSmallScreen ? 12 : 16,
                  ),
                  child: Row(
                    children: [
                      // Option indicator (circle with letter)
                      Container(
                        width: isSmallScreen ? 36 : 44,
                        height: isSmallScreen ? 36 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue.shade500 : Colors.grey.shade200,
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      
                      // Option text content
                      Expanded(
                        child: text.contains(r'$') || text.contains('\\')
                          ? Math.tex(
                              text,
                              textStyle: TextStyle(
                                fontSize: fontSize,
                                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                              ),
                            )
                          : Text(
                              text,
                              style: TextStyle(
                                fontSize: fontSize,
                                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                              ),
                            ),
                      ),
                      
                      // Selected indicator
                      if (isSelected)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.blue.shade500,
                            size: isSmallScreen ? 24 : 28,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } 
    // Fallback for multiple-choice with missing options
    else if (widget.question['type'] == 'multiple-choice') {
      return _buildErrorContainer('Question options are missing. Please refresh the page or contact support.');
    } 
    // Text/numeric answer input for non multiple-choice questions
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Your Answer:',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _submitted 
                      ? Colors.green.shade300
                      : _answer.isEmpty 
                          ? Colors.grey.shade300 
                          : Colors.blue.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                enabled: !_submitted,
                onChanged: (value) {
                  setState(() {
                    _answer = value;
                  });
                },
                autofocus: true,
                keyboardType: widget.question['type'] == 'numeric' 
                    ? TextInputType.number 
                    : TextInputType.text,
                decoration: InputDecoration(
                  hintText: widget.question['type'] == 'numeric'
                      ? 'Enter your numeric answer...'
                      : 'Enter your answer...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontSize: fontSize + 2,
                  color: _submitted ? Colors.grey.shade700 : Colors.black87,
                ),
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
          
          // Show numeric keyboard for numeric questions on small screens
          if (isSmallScreen && widget.question['type'] == 'numeric' && !_submitted)
            Container(
              margin: EdgeInsets.only(top: 12),
              height: 180,
              child: _buildNumericKeypad(),
            ),
        ],
      );
    }
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              widget.question.toString(),
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: NeverScrollableScrollPhysics(),
      children: [
        ...[1, 2, 3, 4, 5, 6, 7, 8, 9, '.', 0, 'DEL'].map((key) {
          return InkWell(
            onTap: () {
              if (key == 'DEL') {
                if (_answer.isNotEmpty) {
                  setState(() {
                    _answer = _answer.substring(0, _answer.length - 1);
                  });
                }
              } else {
                setState(() {
                  // Prevent multiple decimal points
                  if (key == '.' && _answer.contains('.')) return;
                  _answer = _answer + key.toString();
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: key == 'DEL' ? Colors.red.shade100 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: key == 'DEL' ? Colors.red.shade300 : Colors.blue.shade200,
                ),
              ),
              child: Center(
                child: key == 'DEL'
                    ? Icon(Icons.backspace, color: Colors.red.shade700)
                    : Text(
                        key.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}