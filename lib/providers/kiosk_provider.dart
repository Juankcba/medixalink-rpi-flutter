import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KioskProvider with ChangeNotifier {
  bool _isLoading = true;
  bool _isLinked = false;
  String? _deviceId;
  String? _tenantId;
  String? _officeId;
  String? _linkCode;
  
  // Getters
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
    }
    
    _isLoading = false;
    notifyListeners();
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
        _linkCode = data['msg']; // It seems backend returns {msg: ...} but controller logic implies code. Wait, verification step 954 showed {msg: "Use /link endpoint..."}
                                 // Wait! The backend returns {msg: ...} but the frontend expects 'code'.
                                 // Let's check logic. KioskController says: return { msg: 'Use /link endpoint with scanned code' };
                                 // This is wrong! The Device needs to DISPLAY a code.
                                 // The Controller implementation was a placeholder!
        
        // Correcting interpretation: The endpoint creates a PENDING request and returns a code (e.g. "1234")
        // But the current controller code in Step 938 returns a hardcoded msg.
        // That is why it fails or shows weird stuff!
        
        // TEMPORARY FIX: Show what backend returns to debug, or fix backend.
        // The user verified curl returns {"msg":"Use /link endpoint with scanned code"}.
        // The app expects data['code']. data['code'] is null.
        // So _linkCode becomes null.
        
        if (data['code'] != null) {
           _linkCode = data['code'];
        } else {
           _error = "Backend returned no code: ${response.body}";
        }
        notifyListeners();
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
}
