// lib/api_service.dart
import 'constants.dart'; // Importa baseUrl
import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main.dart'; // Para acceder al navigatorKey
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data'; // Para Uint8List
import 'dart:io'; // Para File
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http_parser/http_parser.dart'; // Para MediaType

class ApiService {
  final AuthService _authService;
  late final Dio dio;
  final GlobalKey<NavigatorState> navigatorKey;

  ApiService(this._authService, this.navigatorKey) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl, // Usa baseUrl de constants.dart
        connectTimeout: Duration(milliseconds: 5000),
        receiveTimeout: Duration(milliseconds: 3000),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Añadir Logging Interceptor (opcional)
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => print(obj),
    ));

    // Añadir interceptores para manejar tokens y errores
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Añadir el token de acceso a las solicitudes
        String? token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Si el error es 401, intentar refrescar el token
        if (error.response?.statusCode == 401) {
          try {
            bool tokenRefreshed = await _authService.refreshAccessToken();
            if (tokenRefreshed) {
              final newToken = await _authService.getAccessToken();
              if (newToken != null) {
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                final cloneReq = await dio.request(
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
          } catch (e) {
            // Si falla el refresco, cerrar sesión y redirigir al login
            await _authService.logout();
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
          }
        }
        return handler.next(error);
      },
    ));
  }

  // Método para iniciar sesión utilizando AuthService
  Future<void> login(String username, String password) async {
    await _authService.login(username, password);
  }

  Future<void> getProtectedData() async {
    try {
      final response = await dio.get('/protected');
      if (response.statusCode != 200) {
        throw Exception('Error al obtener datos protegidos');
      }
    } catch (e) {
      throw Exception('Error al obtener datos protegidos: $e');
    }
  }

  // Método para obtener colores
  Future<List<dynamic>> getColors() async {
    try {
      final response = await dio.get('/api/colors');
      return response.data;
    } catch (e) {
      print('Error in getColors: $e');
      rethrow;
    }
  }

  // Método para obtener vehículos
  Future<List<dynamic>> getVehicles({String? vin}) async {
    try {
      final response = await dio.get(
        '/api/vehicles',
        queryParameters: {
          'skip': 0,
          'limit': 20,
          'in_progress': true,
          'vin': vin ?? '',
        },
      );
      return response.data;
    } catch (e) {
      print('Error in getVehicles: $e');
      rethrow;
    }
  }

  // Método para obtener detalles de un vehículo específico
  Future<Map<String, dynamic>> getVehicleDetails(int vehicleId) async {
    try {
      final response = await dio.get('/api/vehicles/$vehicleId');
      return response.data;
    } catch (e) {
      print('Error in getVehicleDetails: $e');
      rethrow;
    }
  }

  // Método para buscar vehículo por VIN
  Future<Map<String, dynamic>> searchVehicleByVin(String vin) async {
    try {
      final response = await dio.get('/api/vehicles/search_by_vin/$vin');
      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 404) {
        throw Exception('No se encontró un vehículo con el VIN proporcionado.');
      } else {
        throw Exception('Error al buscar el vehículo. Código: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 404) {
        throw Exception('No se encontró un vehículo con el VIN proporcionado.');
      } else {
        print('Error al buscar el vehículo: ${e.message}');
        throw Exception('Error al conectar con el servidor. Por favor, inténtelo más tarde.');
      }
    } catch (e) {
      print('Excepción al buscar el vehículo: $e');
      throw Exception('Error al conectar con el servidor. Por favor, inténtelo más tarde.');
    }
  }

  // Método para obtener las transiciones permitidas de un vehículo específico
  Future<List<Map<String, dynamic>>> getAllowedTransitions(int vehicleId) async {
    try {
      final response = await dio.get('/api/vehicles/$vehicleId/allowed_transitions');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error in getAllowedTransitions: $e');
      rethrow;
    }
  }

  // Método para obtener los comentarios permitidos para un estado específico
  Future<List<Map<String, dynamic>>> getCommentsForState(int stateId) async {
    try {
      final response = await dio.get('/api/states/$stateId/comments');

      // Verificar si la respuesta es una lista
      if (response.data is List) {
        // Convertir la respuesta en una lista de mapas
        return List<Map<String, dynamic>>.from(response.data);
      }
      // Verificar si la respuesta es un mapa que contiene la clave 'detail'
      else if (response.data is Map<String, dynamic> && response.data.containsKey('detail')) {
        // Puedes optar por retornar una lista vacía
        return [];
        
        // O, si prefieres manejarlo como un error, puedes lanzar una excepción:
        // throw Exception(response.data['detail']);
      }
      // Manejar formatos de respuesta inesperados
      else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      print('Error in getCommentsForState: $e');
      rethrow; // Re-lanzar la excepción para que pueda ser manejada más arriba
    }
  }

  // Método para cambiar el estado de un vehículo
  Future<void> changeVehicleState(int vehicleId, int newStateId, {int? commentId}) async {
    try {
      // Construir el mapa de datos de forma condicional
      final Map<String, dynamic> data = {
        'new_state_id': newStateId,
        if (commentId != null) 'comment_id': commentId,
      };

      await dio.put(
        '/api/vehicles/$vehicleId/state',
        data: data,
      );
    } catch (e) {
      print('Error in changeVehicleState: $e');
      rethrow; // Re-lanzar la excepción para que pueda ser manejada más arriba
    }
  }





  // Método para subir una imagen
  Future<Map<String, dynamic>> uploadImage(Uint8List? webImage, File? imageFile) async {
    try {
      FormData formData = FormData();

      if (kIsWeb && webImage != null) {
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            webImage,
            filename: 'qr_sample.jpeg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      } else if (imageFile != null) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: 'qr_sample.jpeg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      } else {
        throw Exception('No se ha proporcionado ninguna imagen para subir.');
      }

      final response = await dio.post(
        '/scan',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 400) {
        throw Exception(response.data['error'] ?? 'Error al procesar la imagen.');
      } else {
        throw Exception('Error al subir la imagen. Código de estado: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        throw Exception(e.response!.data['error'] ?? 'Error al procesar la imagen.');
      } else {
        print('Error al subir la imagen: ${e.message}');
        throw Exception('Error al conectar con el servidor. Por favor, inténtelo más tarde.');
      }
    } catch (e) {
      print('Excepción al subir la imagen: $e');
      throw Exception('Error al conectar con el servidor. Por favor, inténtelo más tarde.');
    }
  }



  // Método para cerrar sesión
  Future<void> logout() async {
    try {
      final refreshToken = await _authService.getRefreshToken(); // Obtener el refresh token almacenado

      final response = await dio.post(
        '/logout',
        data: {'refresh_token': refreshToken}
        ); // Asegúrate de que este endpoint exista en tu API

      if (response.statusCode == 200) {
        // Eliminar tokens almacenados
        await _authService.logout();
      } else {
        throw Exception('Error al cerrar sesión en el servidor');
      }
    } catch (e) {
      print('Error en logout: $e');
      throw Exception('Error al cerrar sesión. Por favor, inténtelo de nuevo.');
    }
  }

  // Método para obtener los tipos de vehículos
  Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    try {
      final response = await dio.get('/api/vehicle/types', queryParameters: {'skip': 0, 'limit': 20});
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error in getVehicleTypes: $e');
      rethrow;
    }
  }

  // Método para actualizar un tipo de vehículo
  Future<void> updateVehicleType(int id, String typeName) async {
    try {
      await dio.put(
        '/api/vehicle/types/$id',
        data: {'type_name': typeName},
      );
    } catch (e) {
      print('Error in updateVehicleType: $e');
      rethrow;
    }
  }

  // Método para eliminar un tipo de vehículo
  Future<void> deleteVehicleType(int id) async {
    try {
      await dio.delete('/api/vehicle/types/$id');
    } catch (e) {
      print('Error in deleteVehicleType: $e');
      rethrow;
    }
  }

  // Método para crear un nuevo tipo de vehículo
  Future<void> createVehicleType(String typeName) async {
    try {
      await dio.post(
        '/api/vehicle/types',
        data: {'type_name': typeName},
      );
    } catch (e) {
      print('Error in createVehicleType: $e');
      rethrow;
    }
  }




  // Método para obtener las marcas de vehículos
  Future<List<Map<String, dynamic>>> getVehicleBrands() async {
    try {
      final response = await dio.get('/api/brands', queryParameters: {'skip': 0, 'limit': 10});
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error in getVehicleBrands: $e');
      rethrow;
    }
  }

  // Método para actualizar una marca de vehículo
  Future<void> updateVehicleBrand(int id, String name) async {
    try {
      await dio.put(
        '/api/brands/$id',
        data: {'name': name},
      );
    } catch (e) {
      print('Error in updateVehicleBrand: $e');
      rethrow;
    }
  }

  // Método para eliminar una marca de vehículo
  Future<void> deleteVehicleBrand(int id) async {
    try {
      await dio.delete('/api/brands/$id');
    } catch (e) {
      print('Error in deleteVehicleBrand: $e');
      rethrow;
    }
  }

  // Método para crear una nueva marca de vehículo
  Future<void> createVehicleBrand(String name) async {
    try {
      await dio.post(
        '/api/brands',
        data: {'name': name},
      );
    } catch (e) {
      print('Error in createVehicleBrand: $e');
      rethrow;
    }
  }




  // Método para obtener los modelos de vehículos
  Future<List<Map<String, dynamic>>> getVehicleModels() async {
    try {
      final response = await dio.get('/api/models');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error in getVehicleModels: $e');
      rethrow;
    }
  }

  // Método para actualizar un modelo de vehículo
  Future<void> updateVehicleModel(int id, String name, int brandId, int typeId) async {
    try {
      await dio.put(
        '/api/models/$id',
        data: {
          'name': name,
          'brand_id': brandId,
          'type_id': typeId,
        },
      );
    } catch (e) {
      print('Error in updateVehicleModel: $e');
      rethrow;
    }
  }

  // Método para eliminar un modelo de vehículo
  Future<void> deleteVehicleModel(int id) async {
    try {
      await dio.delete('/api/models/$id');
    } catch (e) {
      print('Error in deleteVehicleModel: $e');
      rethrow;
    }
  }

  // Método para crear un nuevo modelo de vehículo
  Future<void> createVehicleModel(String name, int brandId, int typeId) async {
    try {
      await dio.post(
        '/api/models',
        data: {
          'name': name,
          'brand_id': brandId,
          'type_id': typeId,
        },
      );
    } catch (e) {
      print('Error in createVehicleModel: $e');
      rethrow;
    }
  }




  // Método para obtener los colores de vehículos
  Future<List<Map<String, dynamic>>> getVehicleColors() async {
    final response = await dio.get('/api/colors');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Método para registrar un vehículo
  Future<void> createVehicle({
    required int vehicleModelId,
    required String vin,
    required int colorId,
    required bool isUrgent,
  }) async {

    try {
      await dio.post(
        '/api/vehicles',
        data: {
          'vehicle_model_id': vehicleModelId,
          'vin': vin,
          'color_id': colorId,
          'is_urgent': isUrgent,
        },
      );
    } catch (e) {
      print('Error in createVehicle: $e');
      rethrow;
    }
  }

  // Método para escanear una imagen
  Future<List<Map<String, dynamic>>> scanImage(String imagePath) async {
    // Crear la data del formulario con el campo 'file'
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last, // Nombre de archivo sin ruta completa
        contentType: MediaType('image', 'jpeg'), // Especificar tipo de contenido
      ),
    });

    try {
      final response = await dio.post(
        '/api/scan',
        data: formData,
      );

      // Revisar respuesta exitosa
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['detected_codes']);
      } else {
        throw Exception('Error al escanear la imagen: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }


}
