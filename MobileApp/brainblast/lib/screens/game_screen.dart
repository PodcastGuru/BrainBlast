



import 'package:brainblast/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../models/game.dart';
import 'game_results_screen.dart';
import 'question_display.dart';


class GameScreen extends StatefulWidget {
  final String gameCode;

  const GameScreen({required this.gameCode});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Game? gameState;
  bool loading = true;
  String? error;
  bool showRoundResults = false;
  bool submittedAnswer = false;
  Map<String, dynamic>? currentQuestion;
  Timer? pollTimer;
  String? playerType; // Store the player's type (player1 or player2)
  int currentRound = 1; // Track current round separately
  bool hasJoinedSocketRoom = false;
  bool isLoadingQuestion = false; // Flag to track question loading state
  int fetchRetryCount = 0; // Counter for fetch retries
  
  @override
  void initState() {
    super.initState();
    print('🎮 GameScreen initialized for game: ${widget.gameCode}');
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    // First, fetch the initial game state
    try {
      await fetchGameState();
      
      // Then setup socket and join the game room
      _setupSocketConnection();
      
      // Start polling for updates after initial setup
      pollTimer = Timer.periodic(Duration(seconds: 5), (timer) {
        fetchGameState(isPolling: true);
      });
      
      setState(() {
        loading = false;
      });
    } catch (e) {
      print('❌ Error initializing game: $e');
      setState(() {
        loading = false;
        error = 'Failed to initialize game: $e';
      });
    }
  }

  void _setupSocketConnection() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    // Make sure socket is connected before joining the game
    if (!socketService.isConnected()) {
      print('⚠️ Socket not connected, reconnecting...');
      socketService.reconnect();
    }
    
    // Join the game room
    print('📱 Joining socket room for game: ${widget.gameCode}');
    socketService.joinGame(widget.gameCode);
    hasJoinedSocketRoom = true;
    
    // Setup all the listeners
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    // Listen for game state updates via socket
    socketService.gameState.listen((state) {
      print('📱 Game state update received: ${state['status']}');
      
      if (mounted) {
        // Check if status changed from waiting to active
        final oldStatus = gameState?.status;
        final newStatus = state['status'];
        
        setState(() {
          gameState = Game.fromJson(state);
          
          // Store player type if it's in the state
          if (state['playerType'] != null) {
            final newPlayerType = state['playerType'];
            if (playerType != newPlayerType) {
              print('👤 Player type set/changed to: $newPlayerType');
              playerType = newPlayerType;
            }
          }
          
          // Update current round if available
          if (state['currentRound'] != null) {
            currentRound = state['currentRound'];
          }
          
          // If status changed from waiting to active, that means second player joined
          if (oldStatus == 'waiting' && newStatus == 'active') {
            print('✨ Game activated! Second player joined.');
          }
          
          // Preserve current question if it's your turn
          if (gameState?.status == 'active' && 
              isYourTurn() &&
              state['currentQuestion'] != null) {
            currentQuestion = state['currentQuestion'];
            submittedAnswer = false;
            isLoadingQuestion = false;
            
            print('❓ Current question set: ${state['currentQuestion']['text']}');
          }
        });
        
        // If state just changed to active and it's your turn but no question,
        // force a refresh to get the question
        if ((oldStatus == 'waiting' && newStatus == 'active' && isYourTurn()) ||
            (isYourTurn() && currentQuestion == null && !isLoadingQuestion)) {
          print('⚠️ Game active and it\'s my turn but no question - fetching question');
          _fetchQuestionWithRetry();
        }
      }
    });
    
    // Listen for your turn notification
    socketService.yourTurn.listen((data) {
      print('🎯 Your turn! Round ${data['currentRound']}');
      print('Full data received: $data');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("It's your turn now!"))
      );
      
      if (mounted) {
        setState(() {
          submittedAnswer = false;
          if (data['currentRound'] != null) {
            currentRound = data['currentRound'];
          }
          
          // Set loading flag to show loading state
          isLoadingQuestion = true;
        });
        
        // Immediately fetch question with retry logic
        _fetchQuestionWithRetry();
      }
    });
    
    // Listen for answer processed notification
    socketService.answerProcessed.listen((state) {
      print('✓ Answer processed');
      
      if (mounted) {
        setState(() {
          // Keep UI showing submitted state for the question they just answered
          submittedAnswer = true;
          
          // Update overall game state
          gameState = Game.fromJson(state);
          
          // Update current round if available
          if (state['currentRound'] != null) {
            currentRound = state['currentRound'];
          }
        });
      }
    });
    
    // Listen for round complete notification
    socketService.roundComplete.listen((data) {
      final roundNumber = data['roundNumber'];
      final winner = data['winner'];
      print('🏁 Round $roundNumber complete. Winner: $winner');
      
      if (mounted) {
        setState(() {
          // Show round results
          showRoundResults = true;
          
          // Update current round
          if (data['currentRound'] != null) {
            currentRound = data['currentRound'];
          }
        });
        
        // Refresh game state
        fetchGameState();
        
        // Auto-hide results after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              showRoundResults = false;
            });
          }
        });
      }
    });
    
    // Listen for game complete notification
    socketService.gameComplete.listen((data) {
      print('🎮 Game complete! Winner: ${data['winner']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Game completed!'))
      );
      fetchGameState(); // Get final game state
    });
    
    // Listen for errors
    socketService.error.listen((errorData) {
      print('❌ Socket error: ${errorData['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorData['message'] ?? 'An error occurred'),
          backgroundColor: Colors.red
        )
      );
    });
  }

  // Added function to implement retry logic for fetching questions
  Future<void> _fetchQuestionWithRetry() async {
    setState(() {
      isLoadingQuestion = true;
      fetchRetryCount = 0;
    });
    
    print('🔄 Starting question fetch with retry logic');
    
    // Define a function that we can call recursively
    Future<void> attemptFetch() async {
      try {
        await fetchGameState(forceQuestionFetch: true);
        
        // Check if we got a question after the fetch
        if (currentQuestion != null) {
          // Success! Reset the loading state
          if (mounted) {
            setState(() {
              isLoadingQuestion = false;
              fetchRetryCount = 0;
            });
            print('✅ Question fetched successfully');
          }
        } else {
          // Question still null, increment counter
          fetchRetryCount++;
          
          // Retry up to 3 times with increasing delay
          if (fetchRetryCount < 4 && mounted) {
            print('⚠️ Question still null after fetch. Retry #$fetchRetryCount');
            
            // Calculate exponential backoff delay (0.5s, 1s, 2s)
            int delayMs = 500 * (1 << (fetchRetryCount - 1));
            
            // Show toast about retrying
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Loading question... Retry #$fetchRetryCount'))
            );
            
            // Wait and try again
            Future.delayed(Duration(milliseconds: delayMs), () {
              if (mounted && currentQuestion == null) {
                attemptFetch();
              }
            });
          } else if (mounted) {
            // Give up after max retries
            setState(() {
              isLoadingQuestion = false;
              error = "Failed to load question after multiple attempts";
            });
            
            // Show error toast
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load question. Please try manual refresh.'),
                backgroundColor: Colors.red
              )
            );
          }
        }
      } catch (e) {
        print('❌ Error in retry fetch: $e');
        if (mounted) {
          setState(() {
            isLoadingQuestion = false;
          });
        }
      }
    }
    
    // Start the first attempt
    attemptFetch();
  }

  Future<void> fetchGameState({bool isPolling = false, bool forceQuestionFetch = false}) async {
    try {
      if (!isPolling) {
        print("🔍 Fetching game state for game: ${widget.gameCode}" + 
              (forceQuestionFetch ? " (forcing question fetch)" : ""));
      }
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final result = await apiService.getGameState(widget.gameCode);
      
      // Check if result structure is valid
      if (result != null) {
        // Debug output game state
        if (!isPolling) {
          print("📊 Game data received - Status: ${result['status']}, " +
              "Turn: ${result['currentTurn']}, " +
              "Player type: ${result['player'] != null ? result['player']['type'] : 'unknown'}");
        }
        
        if (mounted) {
          setState(() {
            final oldStatus = gameState?.status;
            gameState = Game.fromJson(result);
            
            // Log status change
            if (oldStatus != gameState?.status && !isPolling) {
              print("⚠️ Game status changed from $oldStatus to ${gameState?.status}");
            }
            
            // Store player type from the nested player object
            if (result['player'] != null && result['player']['type'] != null) {
              final newPlayerType = result['player']['type'];
              if (playerType != newPlayerType && !isPolling) {
                print('👤 Player type set to: $newPlayerType (from nested player object)');
                playerType = newPlayerType;
              }
            }
            
            // Update current round if available
            if (result['currentRound'] != null) {
              currentRound = result['currentRound'];
            }
            
            // Extract the current question if it exists and if it's your turn or we're forcing a fetch
            if (result['currentQuestion'] != null && 
                (isYourTurn() || forceQuestionFetch)) {
              currentQuestion = result['currentQuestion'];
              
              if (!isPolling) {
                print("❓ Current question available: ${result['currentQuestion']['text']}");
              }
              
              // If we're forcing a question fetch and got it, reset the loading state
              if (forceQuestionFetch) {
                isLoadingQuestion = false;
              }
            }
            
            // Reset submitted state if it's your turn and we haven't submitted
            if (gameState?.status == 'active' && isYourTurn()) {
              if (!isPolling && submittedAnswer) {
                print("⚠️ It's my turn but submittedAnswer is true - resetting");
              }
              submittedAnswer = false;
            }
          });
        }
        
        // If we haven't joined the socket room yet and game state is valid, do it now
        if (!hasJoinedSocketRoom) {
          _setupSocketConnection();
        }
        
        // If it's your turn but no question, and we're not already loading one,
        // trigger the question fetch with retry logic
        if (isYourTurn() && currentQuestion == null && !isLoadingQuestion && !forceQuestionFetch) {
          print("⚠️ It's my turn but no question available - starting fetch with retry");
          _fetchQuestionWithRetry();
        }
      } else {
        if (mounted && !isPolling) {
          setState(() {
            error = 'Invalid game state response structure';
          });
          print("⚠️ Invalid game state response structure");
        }
      }
    } catch (e) {
      if (!isPolling) {
        print('❌ Error fetching game state: $e');
        if (mounted) {
          setState(() {
            error = 'Failed to load game. Please try again.';
          });
        }
      }
    }
  }

  void handleSubmitAnswer(String answer, double timeElapsed) {
    if (gameState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Game state not available"))
      );
      return;
    }
    
    // Check if it's your turn
    if (!isYourTurn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not your turn!'))
      );
      return;
    }
    
    // Convert timeElapsed to int (milliseconds) if needed
    final int timeElapsedMs = (timeElapsed * 1000).round();
    
    print('📤 Submitting answer: ${widget.gameCode}, $answer, $timeElapsedMs ms');
    
    // Mark as submitted immediately to prevent double-submission
    setState(() {
      submittedAnswer = true;
    });
    
    // Send answer through socket
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    // Check if socket is connected before submitting
    if (!socketService.isConnected()) {
      print('⚠️ Socket disconnected, reconnecting before submitting answer...');
      socketService.reconnect();
      
      // Give socket a moment to reconnect
      Future.delayed(Duration(milliseconds: 500), () {
        socketService.submitAnswer(widget.gameCode, answer, timeElapsedMs);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Answer submitted!'))
        );
      });
    } else {
      socketService.submitAnswer(widget.gameCode, answer, timeElapsedMs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Answer submitted!'))
      );
    }
  }

  Future<void> handleAbandonGame() async {
    final shouldAbandon = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Abandon Game'),
        content: Text('Are you sure you want to abandon this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Abandon'),
          ),
        ],
      ),
    );
    
    if (shouldAbandon == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final result = await apiService.abandonGame(widget.gameCode);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Game abandoned'))
        );
       Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()));
      } catch (e) {
        print('❌ Error abandoning game: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to abandon game. Please try again.'),
            backgroundColor: Colors.red
          )
        );
      }
    }
  }

  void handleForceRefresh() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Refreshing game state...'))
    );
    
    // Cancel any existing retry attempts
    setState(() {
      isLoadingQuestion = true;
      fetchRetryCount = 0;
    });
    
    // Check socket connection and reconnect if needed
    final socketService = Provider.of<SocketService>(context, listen: false);
    if (!socketService.isConnected()) {
      print('⚠️ Socket disconnected during force refresh, reconnecting...');
      socketService.reconnect();
      socketService.joinGame(widget.gameCode);
    }
    
    // Use the retry logic for fetching
    _fetchQuestionWithRetry();
  }

  // Helper method to check if it's the current player's turn
  bool isYourTurn() {
    if (gameState == null) return false;
    
    // Get player type from the nested structure
    String? myPlayerType = null;
    
    // First try to get from the stored playerType
    if (playerType != null) {
      myPlayerType = playerType;
    } 
    // Then try to get from the player object
    else if (gameState?.player != null) {
      myPlayerType = gameState?.player?.type;
    }
    
    final currentTurn = gameState?.currentTurn;
    
    bool result = myPlayerType != null && currentTurn != null && myPlayerType == currentTurn;
    
    if (result) {
      print('✅ It is my turn! (playerType: $myPlayerType, currentTurn: $currentTurn)');
    } else {
      print('❌ Not my turn. (playerType: $myPlayerType, currentTurn: $currentTurn)');
    }
    
    return result;
  }

  @override
  void dispose() {
    // Cancel the polling timer
    pollTimer?.cancel();
    super.dispose();
  }

  @override
  // Widget build(BuildContext context) {
  //   if (loading) {
  //     return Scaffold(
  //       body: Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             CircularProgressIndicator(),
  //             SizedBox(height: 16),
  //             Text('Loading game...'),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   if (error != null) {
  //     return Scaffold(
  //       body: Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Text(error!, style: TextStyle(color: Colors.red)),
  //             SizedBox(height: 16),
  //             ElevatedButton(
  //               onPressed: handleForceRefresh,
  //               child: Text('Retry'),
  //             ),
  //             SizedBox(height: 16),
  //             ElevatedButton(
  //               onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
  //               child: Text('Back to Dashboard'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   if (gameState == null) {
  //     return Scaffold(
  //       body: Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Text('Game not found or unable to load game state'),
  //             SizedBox(height: 16),
  //             ElevatedButton(
  //               onPressed: handleForceRefresh,
  //               child: Text('Retry'),
  //             ),
  //             SizedBox(height: 8),
  //             ElevatedButton(
  //               onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
  //               child: Text('Back to Dashboard'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   // Waiting for opponent to join
  //   if (gameState!.status == 'waiting') {
  //     return WaitingScreen(
  //       gameCode: widget.gameCode,
  //       onAbandon: handleAbandonGame,
  //       onRefresh: handleForceRefresh,  // Add refresh capability
  //     );
  //   }

  //   // Game completed
  //   if (gameState!.status == 'completed') {
  //     return GameResultsScreen(
  //       gameState: gameState!,
  //       onPlayAgain: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
  //     );
  //   }

  //   // Get scores - adjust based on your Game model structure
  //   final int yourScore = gameState!.yourScore ?? 0;
  //   final int opponentScore = gameState!.opponentScore ?? 0;

  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Math Duel'),
  //       actions: [
  //         // Connection status indicator
  //         Consumer<SocketService>(
  //           builder: (context, socketService, child) {
  //             return Icon(
  //               socketService.isConnected() ? Icons.wifi : Icons.wifi_off,
  //               color: socketService.isConnected() ? Colors.green : Colors.red,
  //             );
  //           },
  //         ),
  //         SizedBox(width: 8),
  //         IconButton(
  //           icon: Icon(Icons.refresh),
  //           onPressed: handleForceRefresh,
  //           tooltip: 'Refresh Game State',
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.exit_to_app),
  //           onPressed: handleAbandonGame,
  //           tooltip: 'Abandon Game',
  //         ),
  //       ],
  //     ),
  //     body: Column(
  //       children: [
  //         // Game info header
  //         Container(
  //           padding: EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: Colors.blue.shade50,
  //             border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
  //           ),
  //           child: Column(
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text('Game Code: ${widget.gameCode}'),
  //                   Text('Round $currentRound'),
  //                 ],
  //               ),
  //               SizedBox(height: 12),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Column(
  //                     children: [
  //                       Text('You (${playerType ?? 'unknown'})'),
  //                       Text(
  //                         '$yourScore',
  //                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                   Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 16),
  //                     child: Text(':', style: TextStyle(fontSize: 24)),
  //                   ),
  //                   Column(
  //                     children: [
  //                       Text('Opponent'),
  //                       Text(
  //                         '$opponentScore',
  //                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: 12),
  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                 decoration: BoxDecoration(
  //                   color: isYourTurn() ? Colors.green.shade100 : Colors.orange.shade100,
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: Text(
  //                   isYourTurn() ? 'Your Turn' : "Opponent's Turn",
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     color: isYourTurn() ? Colors.green.shade800 : Colors.orange.shade800,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
          
  //         // Round results (if showing)
  //         if (showRoundResults && gameState!.rounds != null && gameState!.rounds.isNotEmpty) 
  //           // _buildRoundResultsWidget(),
  //           Container(), // Placeholder for round results
          
  //         // Main content area
  //         Expanded(
  //           child: isYourTurn()
  //               ? submittedAnswer
  //                   ? _buildSubmittedView()
  //                   : isLoadingQuestion || currentQuestion == null
  //                       ? _buildLoadingQuestionView()
  //                       : QuestionDisplayWidget(
  //                           question: currentQuestion!,
  //                           onSubmit: handleSubmitAnswer,
  //                         )
  //               : _buildWaitingForOpponentView(),
  //         ),
          
  //         // Debug info (collapsible)
  //         _buildDebugInfoPanel(),
  //       ],
  //     ),
  //     floatingActionButton: !isYourTurn() || submittedAnswer ? null : FloatingActionButton(
  //       onPressed: handleForceRefresh,
  //       tooltip: 'Refresh',
  //       child: Icon(Icons.refresh),
  //     ),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder for responsive design
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if it's a mobile or desktop layout
        bool isMobile = constraints.maxWidth < 600;

        if (loading) {
          return _buildLoadingScreen();
        }

        if (error != null) {
          return _buildErrorScreen();
        }

        if (gameState == null) {
          return _buildGameNotFoundScreen();
        }

        // Waiting for opponent to join
        if (gameState!.status == 'waiting') {
          return WaitingScreen(
            gameCode: widget.gameCode,
            onAbandon: handleAbandonGame,
            onRefresh: handleForceRefresh,
          );
        }

        // Game completed
        if (gameState!.status == 'completed') {
          return GameResultsScreen(
            gameState: gameState!,
            onPlayAgain: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen())));
          
        }

        // Main game screen
        return Scaffold(
          appBar: _buildAppBar(),
          body: _buildGameBody(isMobile),
          floatingActionButton: !isYourTurn() || submittedAnswer 
            ? null 
            : _buildRefreshFAB(),
        );
      },
    );
  }

 Widget _buildRefreshFAB() {
    return FloatingActionButton(
      onPressed: handleForceRefresh,
      tooltip: 'Refresh',
      child: Icon(Icons.refresh),
    );
  }

  // Loading Screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading game...'),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Math Duel', style: TextStyle(fontSize: 18)),
      actions: [
        Consumer<SocketService>(
          builder: (context, socketService, child) {
            return Icon(
              socketService.isConnected() ? Icons.wifi : Icons.wifi_off,
              color: socketService.isConnected() ? Colors.green : Colors.red,
            );
          },
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: handleForceRefresh,
          tooltip: 'Refresh Game State',
        ),
        IconButton(
          icon: Icon(Icons.exit_to_app),
          onPressed: handleAbandonGame,
          tooltip: 'Abandon Game',
        ),
      ],
    );
  }

// Loading Screen
  // Widget _buildLoadingScreen() {
  //   return Scaffold(
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           CircularProgressIndicator(),
  //           SizedBox(height: 16),
  //           Text('Loading game...'),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Error Screen
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: handleForceRefresh,
              child: Text('Retry'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen())),
              child: Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  // Game Not Found Screen
  Widget _buildGameNotFoundScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Game not found or unable to load game state'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: handleForceRefresh,
              child: Text('Retry'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen())),
              child: Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
  // Responsive Game Body
  Widget _buildGameBody(bool isMobile) {
    return Column(
      children: [
        // Game Info Header (Responsive)
        _buildGameInfoHeader(isMobile),
        
        // Round Results (if showing)
        if (showRoundResults && gameState!.rounds != null && gameState!.rounds.isNotEmpty) 
          Container(), // Placeholder for round results
        
        // Main Content Area (Responsive)
        Expanded(
          child: _buildMainContent(),
        ),
        
        // Debug Info Panel
        // _buildDebugInfoPanel(),
      ],
    );
  }

   Widget _buildMainContent() {
    return isYourTurn()
        ? submittedAnswer
            ? _buildSubmittedView()
            : isLoadingQuestion || currentQuestion == null
                ? _buildLoadingQuestionView()
                : QuestionDisplayWidget(
                    question: currentQuestion!,
                    onSubmit: handleSubmitAnswer,
                  )
        : _buildWaitingForOpponentView();
  }

  // Responsive Game Info Header
  Widget _buildGameInfoHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Game Code: ${widget.gameCode}'),
              Text('Round $currentRound'),
            ],
          ),
          SizedBox(height: 12),
          _buildScoreDisplay(isMobile),
          SizedBox(height: 12),
          _buildTurnIndicator(),
        ],
      ),
    );
  }
   Widget _buildScoreDisplay(bool isMobile) {
    final int yourScore = gameState!.yourScore ?? 0;
    final int opponentScore = gameState!.opponentScore ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPlayerScore('You (${playerType ?? 'unknown'})', yourScore),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(':', style: TextStyle(fontSize: 24)),
        ),
        _buildPlayerScore('Opponent', opponentScore),
      ],
    );
  }

Widget _buildPlayerScore(String playerName, int score) {
    return Column(
      children: [
        Text(playerName),
        Text(
          '$score',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Turn Indicator
  Widget _buildTurnIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isYourTurn() ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isYourTurn() ? 'Your Turn' : "Opponent's Turn",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isYourTurn() ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }


  Widget _buildSubmittedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'Answer Submitted',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Waiting for your opponent to take their turn.'),
          SizedBox(height: 24),
          CircularProgressIndicator(),
          SizedBox(height: 24),
          OutlinedButton(
            onPressed: handleForceRefresh,
            child: Text('Refresh Game State'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingQuestionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isLoadingQuestion 
              ? CircularProgressIndicator()
              : Icon(Icons.error_outline, size: 48, color: Colors.orange),
          SizedBox(height: 24),
          Text(
            isLoadingQuestion ? 'Loading question...' : 'No question found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            isLoadingQuestion 
                ? 'The question should appear shortly.'
                : 'There was a problem loading your question.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          if (fetchRetryCount > 0) 
            Text(
              'Retry attempt: $fetchRetryCount/3',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic
              ),
            ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: handleForceRefresh,
            icon: Icon(Icons.refresh),
            label: Text('Force Refresh'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForOpponentView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            "Waiting for opponent's turn",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("You'll be notified when it's your turn again."),
          SizedBox(height: 24),
          CircularProgressIndicator(),
          SizedBox(height: 24),
          OutlinedButton(
            onPressed: handleForceRefresh,
            child: Text('Refresh Game State'),
          ),
        ],
      ),
    );
  }

//   Widget _buildDebugInfoPanel() {
//     return ExpansionTile(
//       title: Text('Debug Info'),
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Player Type: ${playerType ?? 'Unknown'}'),
//               Text('Current Turn: ${gameState?.currentTurn}'),
//               Text('Is Your Turn: ${isYourTurn() ? 'Yes' : 'No'}'),
//               Text('Game Status: ${gameState?.status}'),
//               Text('Current Round: $currentRound'),
//               Text('Submitted Answer: ${submittedAnswer ? 'Yes' : 'No'}'),
//               Text('Has Current Question: ${currentQuestion != null ? 'Yes' : 'No'}'),
//               Text('Is Loading Question: ${isLoadingQuestion ? 'Yes' : 'No'}'),
//               Text('Fetch Retry Count: $fetchRetryCount'),
//               Text('Has Joined Socket: ${hasJoinedSocketRoom ? 'Yes' : 'No'}'),
              
//               // Socket connection status
//              Consumer<SocketService>(
//                 builder: (context, socketService, child) {
//                   return Row(
//                     children: [
//                       Icon(
//                         socketService.isConnected() ? Icons.check_circle : Icons.cancel,
//                         color: socketService.isConnected() ? Colors.green : Colors.red,
//                         size: 16,
//                       ),
//                       SizedBox(width: 8),
//                       Text('Socket: ${socketService.isConnected() ? 'Connected' : 'Disconnected'}'),
//                     ],
//                   );
//                 },
//               ),
              
//               SizedBox(height: 16),
              
//               ElevatedButton(
//                 onPressed: handleForceRefresh,
//                 child: Text('Force Refresh Game State'),
//               ),
              
//               if (currentQuestion != null) ...[
//                 SizedBox(height: 16),
//                 Text('Question:'),
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(currentQuestion.toString()),
//                 ),
//               ],
              
//               if (gameState?.rounds != null && gameState!.rounds.isNotEmpty) ...[
//                 SizedBox(height: 16),
//                 Text('Latest Round:'),
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(gameState!.rounds.last.toString()),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }
}

// Modified WaitingScreen to support the refresh function
class WaitingScreen extends StatefulWidget {
  final String gameCode;
  final Function onAbandon;
  final Function onRefresh;

  const WaitingScreen({
    required this.gameCode,
    required this.onAbandon,
    required this.onRefresh,
  });

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  bool _copied = false;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.gameCode));
    setState(() {
      _copied = true;
    });
    
    // Reset copied state after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waiting for Opponent'),
        automaticallyImplyLeading: false,
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => widget.onRefresh(),
            tooltip: 'Refresh Game State',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Socket connection status
              Consumer<SocketService>(
                builder: (context, socketService, child) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: socketService.isConnected() ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: socketService.isConnected() ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          socketService.isConnected() ? Icons.wifi : Icons.wifi_off,
                          color: socketService.isConnected() ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          socketService.isConnected() ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: socketService.isConnected() ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              SizedBox(height: 32),
              
              // Animated waiting indicator
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              
              // Waiting message
              Text(
                'Waiting for Opponent',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              
              // Share instructions
              Text(
                'Share this game code with another player:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // Game code display with copy button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.gameCode,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: _handleCopy,
                        icon: Icon(_copied ? Icons.check : Icons.copy),
                        label: Text(_copied ? 'Copied!' : 'Copy'),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Manual refresh button
              ElevatedButton.icon(
                onPressed: () => widget.onRefresh(),
                icon: Icon(Icons.refresh),
                label: Text('Refresh Status'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              
              Spacer(),
              
              // Cancel game button
              OutlinedButton.icon(
                onPressed: () => widget.onAbandon(),
                icon: Icon(Icons.cancel, color: Colors.red),
                label: Text('Cancel Game', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}