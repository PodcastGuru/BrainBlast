import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'game_screen.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> with SingleTickerProviderStateMixin {
  bool _isCreating = false;
  String? _gameCode;
  bool _waitingForOpponent = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  // Game options to match React version
  final Map<String, dynamic> _gameOptions = {
    'difficulty': 'mixed',
    'subject': 'mixed',
    'maxRounds': 5,
    'winningScore': 3
  };

  @override
  void initState() {
    super.initState();
    
    // Animation controller setup - initialize before anything else
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    // Initialize socket listeners
    _setupSocketListeners();
    
    // Check socket connection on init
    // Using Future.microtask to avoid BuildContext issues during initialization
    Future.microtask(() {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (!socketService.isConnected()) {
        print('Socket not connected on init, connecting...');
        socketService.reconnect();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create a Game',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_gameCode == null && !_waitingForOpponent)
                      _buildGameOptionsForm()
                    else if (_gameCode != null && _waitingForOpponent)
                      _buildWaitingScreen(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOptionsForm() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title and heading
            Icon(
              Icons.sports_esports,
              size: 60,
              color: Colors.blue.shade700,
            ),
            SizedBox(height: 16),
            
            Text(
              'Create Your Challenge',
              style: TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Customize your game settings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            
            // Difficulty dropdown
            _buildDropdownField(
              icon: Icons.trending_up,
              label: 'Difficulty Level',
              value: _gameOptions['difficulty'],
              items: {
                'mixed': 'Mixed',
                'easy': 'Easy',
                'medium': 'Medium',
                'hard': 'Hard'
              },
              onChanged: (value) {
                setState(() {
                  _gameOptions['difficulty'] = value;
                });
              },
            ),
            SizedBox(height: 20),
            
            // Subject dropdown
            _buildDropdownField(
              icon: Icons.menu_book,
              label: 'Math Subject',
              value: _gameOptions['subject'],
              items: {
                'mixed': 'All Subjects',
                'algebra': 'Algebra',
                'geometry': 'Geometry',
                'calculus': 'Calculus',
                'statistics': 'Statistics'
              },
              onChanged: (value) {
                setState(() {
                  _gameOptions['subject'] = value;
                });
              },
            ),
            SizedBox(height: 20),
            
            // Max rounds dropdown
            _buildDropdownField(
              icon: Icons.repeat,
              label: 'Number of Rounds',
              value: _gameOptions['maxRounds'],
              items: {
                3: '3 Rounds',
                5: '5 Rounds',
                7: '7 Rounds'
              },
              onChanged: (value) {
                setState(() {
                  _gameOptions['maxRounds'] = value;
                });
              },
            ),
            SizedBox(height: 20),
            
            // Winning score dropdown
            _buildDropdownField(
              icon: Icons.emoji_events,
              label: 'Winning Score',
              value: _gameOptions['winningScore'],
              items: {
                2: '2 Wins',
                3: '3 Wins',
                4: '4 Wins'
              },
              onChanged: (value) {
                setState(() {
                  _gameOptions['winningScore'] = value;
                });
              },
            ),
            SizedBox(height: 32),
            
            // Create button
            SizedBox(
              height: 56,
              child: _isCreating
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _createGame,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue.shade700,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isCreating ? 'Creating...' : 'CREATE GAME',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required dynamic value,
    required Map<dynamic, String> items,
    required Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
              items: items.entries.map((entry) {
                return DropdownMenuItem<dynamic>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingScreen() {
    return Column(
      children: [
        // Waiting animation container
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated waiting icon
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Icon(
                      Icons.hourglass_top,
                      size: 80,
                      color: Colors.blue.shade600,
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              
              Text(
                'Waiting for an opponent',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Share the code below with a friend to start playing',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              
              // Game code display
              Container(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'GAME CODE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _gameCode!,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Copy button
              ElevatedButton.icon(
                icon: Icon(Icons.copy),
                label: Text('Copy Code'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  backgroundColor: Colors.blue.shade50,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _gameCode!)).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Game code copied to clipboard!'),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                    );
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        
        // Connection status
        Consumer<SocketService>(
          builder: (context, socketService, child) {
            final isConnected = socketService.isConnected();
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isConnected 
                    ? Colors.green.withOpacity(0.2) 
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConnected ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      Text(
                        isConnected 
                            ? 'Game is ready to start' 
                            : 'Connection lost. Try refreshing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        
        SizedBox(height: 24),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Refresh button
            OutlinedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade300),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _refreshSocketConnection,
            ),
            SizedBox(width: 16),
            
            // Cancel button
            ElevatedButton.icon(
              icon: Icon(Icons.cancel),
              label: Text('Cancel Game'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade600,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _cancelGame,
            ),
          ],
        ),
      ],
    );
  }

  void _setupSocketListeners() {
    // ... socket listener code remains the same ...
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    // Listen for game state updates
    socketService.gameState.listen((gameState) {
      print('📱 Received game state update: ${gameState['status']}');
      
      if (mounted && gameState['status'] == 'active' && _gameCode != null) {
        print('🎮 Game is now active! Navigating to game screen...');
        
        // Game has started, navigate to game screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => GameScreen(gameCode: _gameCode!)),
        );
      }
    });
    
    // Optional: Listen for errors
    socketService.error.listen((errorData) {
      print('❌ Socket error: ${errorData['message']}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _refreshSocketConnection() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    if (!socketService.isConnected()) {
      print('⚠️ Socket disconnected, reconnecting...');
      socketService.reconnect();
    }
    
    if (_gameCode != null) {
      print('🔄 Rejoining game room: $_gameCode');
      socketService.joinGame(_gameCode!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 10),
              Text('Connection refreshed'),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
      );
    }
  }
  
  void _cancelGame() async {
    if (_gameCode == null) return;
    
    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Game'),
        content: Text('Are you sure you want to cancel this game?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (shouldCancel != true) return;
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Attempt to cancel/abandon the game
      // await apiService.abandonGame(_gameCode!);
      
      setState(() {
        _gameCode = null;
        _waitingForOpponent = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Game cancelled'),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
      );
    } catch (e) {
      print('❌ Error cancelling game: $e');
      
      // If API call failed, still reset local state
      setState(() {
        _gameCode = null;
        _waitingForOpponent = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text('Game cancelled (offline)'),
            ],
          ),
          backgroundColor: Colors.amber.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
      );
    }
  }

  void _createGame() async {
    print('📝 Creating game with options: $_gameOptions');
    
    setState(() {
      _isCreating = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);
      
      // Pass game options to API - FIXED: Passing options here
      final result = await apiService.createGame(_gameOptions);
      
      print('✅ Game created successfully: $result');
      final gameCode = result['gameCode'];
      
      // Ensure socket is connected before joining
      if (!socketService.isConnected()) {
        print('⚠️ Socket not connected, reconnecting before joining game...');
        socketService.reconnect();
        
        // Wait a moment for connection to establish
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // Join the game via socket
      print('📱 Joining socket room for game: $gameCode');
      socketService.joinGame(gameCode);
      
      setState(() {
        _gameCode = gameCode;
        _waitingForOpponent = true;
        _isCreating = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Game created! Waiting for an opponent...'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
      );
    } catch (e) {
      print('❌ Error creating game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Failed to create game: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
      );
      setState(() {
        _isCreating = false;
      });
    }
  }
}