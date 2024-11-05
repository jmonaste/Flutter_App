// lib/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'auth_provider.dart';
import 'main.dart';
import 'constants.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

class DioClient {
  final Dio _dio = Dio();
  final String baseUrl = String.fromEnvironment('baseUrl'); // Reemplaza con tu URL base

  DioClient(BuildContext context) {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Obtener el Access Token desde AuthProvider
        String? accessToken = Provider.of<AuthProvider>(context, listen: false).accessToken;
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          RequestOptions options = error.requestOptions;

          bool tokenRefreshed = await _refreshToken(context);
          if (tokenRefreshed) {
            String? newAccessToken = Provider.of<AuthProvider>(context, listen: false).accessToken;
            if (newAccessToken != null) {
              options.headers['Authorization'] = 'Bearer $newAccessToken';
              final cloneReq = await _dio.request(
                options.path,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                ),
                data: options.data,
                queryParameters: options.queryParameters,
              );
              return handler.resolve(cloneReq);
            }
          }

          // Si la renovación falla, redirigir al usuario al login
          await Provider.of<AuthProvider>(context, listen: false).clearTokens();
          _navigateToLogin();
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  /// Intenta renovar el Access Token usando el Refresh Token
  Future<bool> _refreshToken(BuildContext context) async {
    String? refreshToken = Provider.of<AuthProvider>(context, listen: false).refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post(
        '/api/token/refresh', // Reemplaza con tu endpoint de renovación
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );

      if (response.statusCode == 200) {
        String newAccessToken = response.data['access_token'];
        String newRefreshToken = response.data['refresh_token'];

        await Provider.of<AuthProvider>(context, listen: false).setTokens(newAccessToken, newRefreshToken);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error en _refreshToken: $e');
      return false;
    }
  }

  /// Navega al usuario a la página de login
  void _navigateToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }
}
