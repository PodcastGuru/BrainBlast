// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'dart:async';

// class SocketService {
//   late IO.Socket socket;
//   final StreamController<Map<String, dynamic>> _gameStateController = StreamController<Map<String, dynamic>>.broadcast();
//   final StreamController<Map<String, dynamic>> _yourTurnController = StreamController<Map<String, dynamic>>.broadcast();
//   final StreamController<Map<String, dynamic>> _answerProcessedController = StreamController<Map<String, dynamic>>.broadcast();
//   final StreamController<Map<String, dynamic>> _roundCompleteController = StreamController<Map<String, dynamic>>.broadcast();
//   final StreamController<Map<String, dynamic>> _gameCompleteController = StreamController<Map<String, dynamic>>.broadcast();
//   final StreamController<Map<String, dynamic>> _errorController = StreamController<Map<String, dynamic>>.broadcast();

//   Stream<Map<String, dynamic>> get gameState => _gameStateController.stream;
//   Stream<Map<String, dynamic>> get yourTurn => _yourTurnController.stream;
//   Stream<Map<String, dynamic>> get answerProcessed => _answerProcessedController.stream;
//   Stream<Map<String, dynamic>> get roundComplete => _roundCompleteController.stream;
//   Stream<Map<String, dynamic>> get gameComplete => _gameCompleteController.stream;
//   Stream<Map<String, dynamic>> get error => _errorController.stream;

//   void init(String serverUrl, String token) {
//     socket = IO.io("https://xbordr.com", 
//       IO.OptionBuilder()
//         .setTransports(['websocket'])
//         .disableAutoConnect()
//         .setAuth({'token': token})
//         .build()
//     );

//     socket.connect();

//     socket.on('connect', (_) {
//       print('Connected to socket server');
//     });

//     socket.on('game:state', (data) {
//       _gameStateController.add(data);
//     });

//     socket.on('game:yourTurn', (data) {
//       _yourTurnController.add(data);
//     });

//     socket.on('game:answerProcessed', (data) {
//       _answerProcessedController.add(data);
//     });

//     socket.on('game:roundComplete', (data) {
//       _roundCompleteController.add(data);
//     });

//     socket.on('game:complete', (data) {
//       _gameCompleteController.add(data);
//     });
    
//     socket.on('error', (data) {
//       _errorController.add(data is Map<String, dynamic> ? data : {'message': data.toString()});
//     });

//     socket.on('disconnect', (_) {
//       print('Disconnected from socket server');
//     });
    
//     // Add a catch-all error handler for socket connection issues
//     socket.onError((error) {
//       print('Socket error: $error');
//       _errorController.add({'message': 'Connection error: $error'});
//     });
    
//     socket.onConnectError((error) {
//       print('Socket connect error: $error');
//       _errorController.add({'message': 'Failed to connect: $error'});
//     });
//   }

//   void joinGame(String gameCode) {
//     socket.emit('game:join', {'gameCode': gameCode});
//   }

//   void submitAnswer(String gameCode, String answer, int timeElapsed) {
//     socket.emit('game:submitAnswer', {
//       'gameCode': gameCode,
//       'answer': answer,
//       'timeElapsed': timeElapsed
//     });
//   }

//   void dispose() {
//     socket.disconnect();
//     _gameStateController.close();
//     _yourTurnController.close();
//     _answerProcessedController.close();
//     _roundCompleteController.close();
//     _gameCompleteController.close();
//     _errorController.close();
//   }
// }



import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SocketService {
  late IO.Socket socket;
  final StreamController<Map<String, dynamic>> _gameStateController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _yourTurnController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _answerProcessedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _roundCompleteController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _gameCompleteController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController = StreamController<Map<String, dynamic>>.broadcast();
  
  String? _currentGameCode;
  bool _isInitialized = false;

  Stream<Map<String, dynamic>> get gameState => _gameStateController.stream;
  Stream<Map<String, dynamic>> get yourTurn => _yourTurnController.stream;
  Stream<Map<String, dynamic>> get answerProcessed => _answerProcessedController.stream;
  Stream<Map<String, dynamic>> get roundComplete => _roundCompleteController.stream;
  Stream<Map<String, dynamic>> get gameComplete => _gameCompleteController.stream;
  Stream<Map<String, dynamic>> get error => _errorController.stream;

  void init(String serverUrl, String token) {
    if (_isInitialized) {
      print('Socket service already initialized');
      return;
    }
    
    _isInitialized = true;
    
    print('🔌 Initializing socket connection to https://xbordr.com');
    socket = IO.io("https://xbordr.com", 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setAuth({'token': token})
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000)
        .build()
    );

    socket.connect();

    socket.on('connect', (_) {
      print('✅ Connected to socket server');
      
      // If we already have a game code, join the game room
      if (_currentGameCode != null) {
        joinGame(_currentGameCode!);
      }
    });

    socket.on('game:state', (data) {
      print('📩 Received game:state update: ${data['status']}');
      _gameStateController.add(data);
    });

    socket.on('game:yourTurn', (data) {
      print('🎯 Your turn notification received: ${data['currentRound']}');
      _yourTurnController.add(data);
    });

    socket.on('game:answerProcessed', (data) {
      print('✓ Answer processed notification received');
      _answerProcessedController.add(data);
    });

    socket.on('game:roundComplete', (data) {
      print('🏁 Round ${data['roundNumber']} complete. Winner: ${data['winner']}');
      _roundCompleteController.add(data);
    });

    socket.on('game:complete', (data) {
      print('🎮 Game complete! Winner: ${data['winner']}');
      _gameCompleteController.add(data);
    });
    
    socket.on('error', (data) {
      print('❌ Socket error event: $data');
      _errorController.add(data is Map<String, dynamic> ? data : {'message': data.toString()});
    });

    socket.on('disconnect', (_) {
      print('❗ Disconnected from socket server');
    });
    
    // Add a catch-all error handler for socket connection issues
    socket.onError((error) {
      print('⚠️ Socket error: $error');
      _errorController.add({'message': 'Connection error: $error'});
    });
    
    socket.onConnectError((error) {
      print('⚠️ Socket connect error: $error');
      _errorController.add({'message': 'Failed to connect: $error'});
    });
    
    // Debug events (uncomment if needed)
    socket.onAny((event, data) {
      print('📡 Socket event: $event');
      // Uncomment to see detailed data
      // print('📦 Data: $data');
    });
  }

  void joinGame(String gameCode) {
    _currentGameCode = gameCode;
    
    if (!socket.connected) {
      print('⚠️ Socket not connected, attempting to connect before joining game');
      socket.connect();
      return;
    }
    
    print('🎮 Joining game room: $gameCode');
    socket.emit('game:join', {'gameCode': gameCode});
    socket.emit('game:state',{'gameCode': gameCode});
  }

  void submitAnswer(String gameCode, String answer, int timeElapsed) {
    if (!socket.connected) {
      print('⚠️ Socket not connected! Cannot submit answer.');
      _errorController.add({'message': 'Cannot submit answer: socket not connected'});
      return;
    }
    
    print('📤 Submitting answer: $answer, time: $timeElapsed ms');
    socket.emit('game:submitAnswer', {
      'gameCode': gameCode,
      'answer': answer,
      'timeElapsed': timeElapsed
    });
  }

  bool isConnected() {
    return socket.connected;
  }

  void reconnect() {
    if (!socket.connected ) {
      print('🔄 Attempting to reconnect socket...');
      socket.connect();
    }
  }

  void dispose() {
    socket.disconnect();
    _currentGameCode = null;
    _isInitialized = false;
    _gameStateController.close();
    _yourTurnController.close();
    _answerProcessedController.close();
    _roundCompleteController.close();
    _gameCompleteController.close();
    _errorController.close();
    
    print('🔌 Socket service disposed');
  }
}
