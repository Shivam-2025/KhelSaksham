import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://khelsaksham.onrender.com", // ⬅️ use 127.0.0.1 if running on real device with port forwarding
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    _loadTokens(); // auto-load tokens when service starts
  }

  // ---------------------------
  // Token Management
  // ---------------------------
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString("access_token");
    _refreshToken = prefs.getString("refresh_token");
  }

  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", access);
    await prefs.setString("refresh_token", refresh);
    _accessToken = access;
    _refreshToken = refresh;
  }

  void setToken(String token) {
    _accessToken = token;
  }

Options _authOptions({bool isMultipart = false}) {
  if (_accessToken == null) throw Exception("No access token set. Please login first.");

  return Options(
    headers: {
      "Authorization": "Bearer $_accessToken",
      if (!isMultipart) "Content-Type": "application/json",
      // ❗ When multipart, do NOT set content-type → Dio will set boundary automatically
    },
  );
}


  // ---------------------------
  // Profile & History
  // ---------------------------
  Future<Response> getProfile() async {
    return await _dio.get(
      "/profile/me",
      options: _authOptions(),
    );
  }

  Future<Response> updateProfile({
    String? email,
    String? bio,
    String? avatarUrl,
  }) async {
    return await _dio.patch(
      "/profile/me",
      data: {
        if (email != null) "email": email,
        if (bio != null) "bio": bio,
        if (avatarUrl != null) "avatar_url": avatarUrl,
      },
      options: _authOptions(),
    );
  }

  Future<Response> getUserHistory() async {
    return await _dio.get(
      "/user/history",
      options: _authOptions(),
    );
  }

  // ---------------------------
  // Achievements
  // ---------------------------
  Future<Response> getAchievements() async {
    return await _dio.get(
      "/achievements/me",
      options: _authOptions(),
    );
  }

  // ---------------------------
  // Dashboard & Leaderboard
  // ---------------------------
  Future<Response> getDashboard() async {
    return await _dio.get(
      "/dashboard/me",
      options: _authOptions(),
    );
  }

  /// ---------------------------
  /// Leaderboard fetch + mapping
  /// ---------------------------
  Future<List<Map<String, dynamic>>> fetchLeaderboard({String? exercise}) async {
    try {
      final response = await _dio.get(
        "/leaderboard",
        queryParameters: exercise != null ? {"exercise": exercise} : null,
        options: _authOptions(),
      );

      if (response.data == null || response.data is! List) return [];

      final List<dynamic> data = response.data;

      // Map backend data to the structure the UI expects
      List<Map<String, dynamic>> leaderboard = data.map<Map<String, dynamic>>((item) {
        return {
          "id": item["user_id"] ?? 0,
          "name": item["username"] ?? "Unknown",
          "location": item["location"] ?? "",
          "score": item["best"] ?? 0,
          "avatar": item["avatar_url"] ?? "https://i.pravatar.cc/400?u=${item["user_id"]}",
          "rank": 0, // Will be computed after sorting
          "previousRank": item["previous_rank"] ?? 0,
          "sport": item["sport"] ?? "Unknown",
        };
      }).toList();

      // Compute ranks based on score descending
      leaderboard.sort((a, b) => b["score"].compareTo(a["score"]));
      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i]["rank"] = i + 1;
      }

      return leaderboard;
    } catch (e) {
      print("Leaderboard fetch error: $e");
      return [];
    }
  }

  // ---------------------------
  // Auth
  // ---------------------------
  Future<Response> login(String email, String password) async {
    final response = await _dio.post("/login", data: {
      "email": email,
      "password": password,
    });

    if (response.data != null && response.data["access_token"] != null) {
      await _saveTokens(
        response.data["access_token"],
        response.data["refresh_token"],
      );
    }

    return response;
  }

  Future<Response> register(String username, String email, String password,int age,String location , String sport) async {
    final response = await _dio.post("/register", data: {
      "username": username,
      "email": email,
      "password": password,
      "age": age,
      "location": location,
      "sport": sport,  
    });

    // backend register might not return tokens, but just in case:
    if (response.data != null && response.data["access_token"] != null) {
      await _saveTokens(
        response.data["access_token"],
        response.data["refresh_token"],
      );
    }

    return response;
  }

  Future<Response> refreshToken() async {
    if (_refreshToken == null) {
      throw Exception("No refresh token available.");
    }
    final response = await _dio.post("/refresh", data: {
      "refresh_token": _refreshToken,
    });

    if (response.data != null && response.data["access_token"] != null) {
      await _saveTokens(
        response.data["access_token"],
        _refreshToken!, // keep old refresh token
      );
    }

    return response;
  }

  // ---------------------------
  // Results
  // ---------------------------
  Future<Response> saveResult(Map<String, dynamic> result) async {
    return await _dio.post(
      "/results",
      data: result,
      options: _authOptions(),
    );
  }

  Future<Response> submitResult({
    required File file,
    required String exercise,
    required int reps,
    required String videoHash,
  }) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
      "exercise": exercise,
      "reps": reps,
      "video_hash": videoHash,
    });

    return await _dio.post(
      "/submit",
      data: formData,
      options: _authOptions(isMultipart: true),
    );
  }

  // ---------------------------
  // Upload
  // ---------------------------
  Future<Response> uploadVideo(File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    return await _dio.post(
      "/upload",
      data: formData,
      options: _authOptions(isMultipart: true),
    );
  }
}

// ✅ Global singleton
final api = ApiService();
