import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://xbordr.com/service/api'; // Replace with your actual API URL
  String? _token;

  // Getter for token
  String? get token => _token;

  // User Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': username, 'password': password}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _token = data['token'];
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }

   Future<Map<String, dynamic>> getGameState(String gameCode) async {
    try {
      final result = await authGet('games/$gameCode');
      
      // Check the response structure - handle nested data object if present
      if (result['data'] != null && result['data']['data'] != null) {
        return result['data']['data'];
      } else if (result['data'] != null) {
        return result['data'];
      } else {
        throw Exception('Invalid response format: missing data field');
      }
    } catch (e) {
      print('Get game state error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> abandonGame(String gameCode) async {
    try {
      final result = await authPost('games/$gameCode/abandon', {});
      return result['data'];
    } catch (e) {
      print('Abandon game error: $e');
      rethrow;
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get profile with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }

  // Create a new game
  Future<Map<String, dynamic>> createGame(gameOptions) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      print(data);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'gameCode': data['data']['gameCode'],
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create game with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }

  // Join an existing game


Future<Map<String, dynamic>> joinGame(String gameCode,) async {
  try {
    // Debugging prints
    print("Joining game with code: $gameCode");
    print("Using token: $token");

    // Making the request
    final response = await http.post(
      Uri.parse('$baseUrl/games/join'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'gameCode': gameCode}),
    );

    // Debugging prints
    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    // Parsing the response
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': data,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to join game (Status Code: ${response.statusCode})',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Network or server error: ${e.toString()}',
    };
  }
}


  // Get game details
  Future<Map<String, dynamic>> getGameDetails(String gameId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get game details with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }

  // Get user game history
  Future<Map<String, dynamic>> getGameHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/games'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'games': data['games'],
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get game history with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }

  // General method for making authenticated GET requests
  Future<Map<String, dynamic>> authGet(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }

  // General method for making authenticated POST requests
  Future<Map<String, dynamic>> authPost(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network or server error: ${e.toString()}'
      };
    }
  }
}