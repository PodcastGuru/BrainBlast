// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import '../services/api_service.dart';
// import '../services/socket_service.dart';
// import 'game_screen.dart';

// class JoinGameScreen extends StatefulWidget {
//   const JoinGameScreen({super.key});

//   @override
//   _JoinGameScreenState createState() => _JoinGameScreenState();
// }

// class _JoinGameScreenState extends State<JoinGameScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _gameCodeController = TextEditingController();
//   bool _isJoining = false;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _setupSocketListeners();
//   }

//   void _setupSocketListeners() {
//     final socketService = Provider.of<SocketService>(context, listen: false);
    
//     // Listen for game state updates
//     socketService.gameState.listen((gameState) {
//       // Game state received, navigate to game screen
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (context) => GameScreen(
//               gameCode: _gameCodeController.text.toUpperCase(),
//             ),
//           ),
//         );
//       }
//     });
    
//     // Listen for any errors
//     socketService.error.listen((errorData) {
//       if (mounted) {
//         setState(() {
//           _isJoining = false;
//           _errorMessage = errorData['message'] ?? 'Failed to join game';
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(_errorMessage!)),
//         );
//       }
//     });
//   }

//   void _joinGame() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isJoining = true;
//         _errorMessage = null;
//       });

//       try {
//         final apiService = Provider.of<ApiService>(context, listen: false);
//         final socketService = Provider.of<SocketService>(context, listen: false);
        
//         final gameCode = _gameCodeController.text.toUpperCase();
        
//         // Join the game via API
//         final result = await apiService.joinGame(gameCode);
        
//         if (result['success'] == false) {
//           setState(() {
//             _isJoining = false;
//             _errorMessage = result['message'] ?? 'Failed to join game';
//           });
          
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(_errorMessage!)),
//           );
//           return;
//         }
        
//         // Join the game via socket
//         socketService.joinGame(gameCode);
        
//       } catch (e) {
//         setState(() {
//           _isJoining = false;
//           _errorMessage = e.toString();
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to join game: ${e.toString()}')),
//         );
//       }
//     }
//   }
  
//   Future<void> _pasteFromClipboard() async {
//     final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
//     if (clipboardData != null && clipboardData.text != null) {
//       setState(() {
//         _gameCodeController.text = clipboardData.text!.trim();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Join a Game'),
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.sports_esports,
//                         size: 64,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       SizedBox(height: 24),
//                       Text(
//                         'Join an Existing Game',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'Enter the game code shared by your opponent',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 40),
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                             color: _errorMessage != null 
//                                 ? Colors.red 
//                                 : Colors.grey[300]!,
//                             width: 2,
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextFormField(
//                                 controller: _gameCodeController,
//                                 decoration: InputDecoration(
//                                   hintText: 'e.g. AB123X',
//                                   contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 16,
//                                   ),
//                                   border: InputBorder.none,
//                                 ),
//                                 textCapitalization: TextCapitalization.characters,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 24,
//                                   letterSpacing: 4,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter a game code';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.content_paste),
//                               onPressed: _pasteFromClipboard,
//                               tooltip: 'Paste from clipboard',
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (_errorMessage != null)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Text(
//                             _errorMessage!,
//                             style: TextStyle(
//                               color: Colors.red,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 _isJoining
//                     ? Center(
//                         child: Column(
//                           children: [
//                             CircularProgressIndicator(),
//                             SizedBox(height: 16),
//                             Text('Joining game...'),
//                           ],
//                         ),
//                       )
//                     : ElevatedButton(
//                         onPressed: _joinGame,
//                         style: ElevatedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: Text(
//                           'Join Game',
//                           style: TextStyle(fontSize: 18),
//                         ),
//                       ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _gameCodeController.dispose();
//     super.dispose();
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'game_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({Key? key}) : super(key: key);

  @override
  _JoinGameScreenState createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameCodeController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;
  final FocusNode _gameCodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    socketService.gameState.listen((gameState) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameScreen(
              gameCode: _gameCodeController.text.toUpperCase(),
            ),
          ),
        );
      }
    });
    
    socketService.error.listen((errorData) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = errorData['message'] ?? 'Failed to join game';
        });
        
        _showErrorSnackBar(_errorMessage!);
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _joinGame() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isJoining = true;
        _errorMessage = null;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final socketService = Provider.of<SocketService>(context, listen: false);
        
        final gameCode = _gameCodeController.text.toUpperCase().trim();
        
        // Join the game via API
        final result = await apiService.joinGame(gameCode);
        
        if (result['success'] == false) {
          setState(() {
            _isJoining = false;
            _errorMessage = result['message'] ?? 'Failed to join game';
          });
          
          _showErrorSnackBar(_errorMessage!);
          return;
        }
        
        // Join the game via socket
        socketService.joinGame(gameCode);
        
      } catch (e) {
        setState(() {
          _isJoining = false;
          _errorMessage = e.toString();
        });
        
        _showErrorSnackBar('Failed to join game: ${e.toString()}');
      }
    }
  }
  
  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _gameCodeController.text = clipboardData.text!.trim().toUpperCase();
      });
      
      // Trigger validation
      _formKey.currentState?.validate();
      
      // Focus on the input
      _gameCodeFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size and orientation
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05,
                vertical: screenSize.height * 0.03,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Animated Game Logo
                    FadeInDown(
                      duration: Duration(milliseconds: 600),
                      child: Hero(
                        tag: 'game-logo',
                        child: Icon(
                          Icons.sports_esports_outlined,
                          size: isPortrait ? screenSize.width * 0.25 : screenSize.height * 0.25,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.03),

                    // Title and Subtitle
                    FadeInUp(
                      duration: Duration(milliseconds: 600),
                      child: Column(
                        children: [
                          Text(
                            'Join Game',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.headlineMedium?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Enter the game code shared by your opponent',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.05),

                    // Game Code Input
                    FadeInUp(
                      duration: Duration(milliseconds: 700),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _gameCodeController,
                          focusNode: _gameCodeFocusNode,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            hintText: 'Game Code (e.g. AB123X)',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              letterSpacing: 2,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.content_paste_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: _pasteFromClipboard,
                              tooltip: 'Paste Game Code',
                            ),
                            errorStyle: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a game code';
                            }
                            // Optional: Add more specific validation if needed
                            return null;
                          },
                        ),
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null)
                      FadeInUp(
                        duration: Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    SizedBox(height: screenSize.height * 0.05),

                    // Join Game Button
                    FadeInUp(
                      duration: Duration(milliseconds: 800),
                      child: _isJoining
                          ? Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Joining game...',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _joinGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                'Join Game',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameCodeController.dispose();
    _gameCodeFocusNode.dispose();
    super.dispose();
  }
}