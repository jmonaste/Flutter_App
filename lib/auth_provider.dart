// lib/auth_provider.dart
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final SecureStorageService _storageService = SecureStorageService();
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> loadTokens() async {
    _accessToken = await _storageService.readAccessToken();
    _refreshToken = await _storageService.readRefreshToken();
    notifyListeners();
  }

  Future<void> setTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storageService.writeAccessToken(access);
    await _storageService.writeRefreshToken(refresh);
    notifyListeners();
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storageService.deleteTokens();
    notifyListeners();
  }
}
