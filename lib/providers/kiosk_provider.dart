import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/socket_service.dart';

class KioskProvider with ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false; 
  bool _isLinked = false;
  
  String? _deviceId;
  String? _tenantId;
  String? _officeId;
  String? _linkCode;
  
  final SocketService _socketService = SocketService();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLinked => _isLinked;
  
  String? get deviceId => _deviceId;
  String? get tenantId => _tenantId;
  String? get linkCode => _linkCode;

  KioskProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auto-generate Request ID / Device ID if not present
    _deviceId = prefs.getString('deviceId');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('deviceId', _deviceId!);
    }

    _tenantId = prefs.getString('tenantId');
    _officeId = prefs.getString('officeId');
    
    if (_tenantId != null) {
      _isLinked = true;
    } else {
      // Connect to socket only if not linked (or always? valid to update config)
      _connectSocket();
    }
    
    _isInitialized = true;
    notifyListeners();
  }
  
  void _connectSocket() {
    if (_deviceId == null) return;
    
    _socketService.initSocket(_deviceId!);
    _socketService.onKioskLinked = (data) {
      print("Kiosk Linked Event Data: $data");
      // Data expected: { tenantId: string, name: string, type: string, officeId?: string }
      if (data != null) {
        setConfig(Map<String, dynamic>.from(data));
      }
    };
  }
  
  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
  
  String? _error; // Store error message
  String? get error => _error; // Expose error

  // Fetch a temporary link code from the backend to display as QR
  Future<void> fetchLinkCode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/kiosk/devices/link-code');
      // We send deviceId to identify this request
      final response = await http.post(
        url, 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'deviceId': _deviceId}),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Check if device is already linked (Backend returns 201 with status: already_linked)
        if (data['status'] == 'already_linked') {
           print("Device already linked (201). Recovering config...");
           await _fetchExistingConfig();
           return;
        }

        // Check if 'code' exists, otherwise check for 'msg' just in case of mismatch
        if (data['code'] != null) {
           _linkCode = data['code'];
        } else if (data['msg'] != null && data['msg'].toString().startsWith('K-')) {
           // Fallback if backend sends code in 'msg'
           _linkCode = data['msg'];
        } else {
           _linkCode = null; // Ensure null so UI shows error
           _error = "Respuesta del servidor inválida: ${response.body}";
        }
        
        // Ensure socket is connected to receive the linking confirmation
        _connectSocket();
        
        notifyListeners();
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        // Device likely already linked. Try to recover configuration.
        final errorMsg = response.body.toLowerCase();
        if (errorMsg.contains("already linked") || errorMsg.contains("already_linked")) {
           print("Device already linked. Attempting to fetch existing config...");
           await _fetchExistingConfig();
        } else {
           _error = "Error: ${response.body}";
        }
      } else {
        _error = "HTTP ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      print('Error fetching link code: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Called when we receive a configuration update via Socket or manual check
  Future<void> setConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (config['tenantId'] != null) {
      _tenantId = config['tenantId'];
      await prefs.setString('tenantId', _tenantId!);
    }
    
    if (config['officeId'] != null) {
      _officeId = config['officeId'];
      await prefs.setString('officeId', _officeId!);
    }
    
    _isLinked = true;
    notifyListeners();
  }

  Future<void> _fetchExistingConfig() async {
     try {
       final url = Uri.parse('${AppConstants.apiBaseUrl}/kiosk/devices/$_deviceId/config');
       final response = await http.get(url);
       
       if (response.statusCode == 200) {
         final data = json.decode(response.body);
         await setConfig(Map<String, dynamic>.from(data));
         // Ensure socket connection upon recovery
         _connectSocket();
       } else {
         _error = "No se pudo recuperar la configuración: ${response.body}";
       }
     } catch (e) {
       _error = "Error recuperando config: $e";
     }
  }

  // Perform Check-in
  Future<Map<String, dynamic>> performCheckIn(String dni) async {
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/kiosk/check-in');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': _deviceId,
          'dni': dni,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['message'] ?? 'Error al realizar check-in');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
