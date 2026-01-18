import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/kiosk_provider.dart';
import 'dart:async'; // Added for Timer

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes default
  static const int _totalSeconds = 300;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCode();
    });
  }

  void _fetchCode() async {
    final kiosk = Provider.of<KioskProvider>(context, listen: false);
    await kiosk.fetchLinkCode();
    _startTimer();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    
    setState(() {
      _secondsRemaining = _totalSeconds;
    });

    // Auto-refresh when code expires
    _refreshTimer = Timer(const Duration(seconds: _totalSeconds), () {
      _fetchCode();
    });

    // Update UI countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kiosk = Provider.of<KioskProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              // Left Column: Info & Instructions
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.link, size: 48, color: Colors.blueGrey),
                    const SizedBox(height: 16),
                    const Text(
                      'Vincular Kiosco',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ingresa el código en el Panel de Admin para vincular este dispositivo.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin > Configuración > Kioscos > Nuevo',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    
                    const Spacer(),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEVICE ID',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Text(
                            kiosk.deviceId ?? "...",
                            style: const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 40),
              
              // Right Column: QR Code & Code Display
              Expanded(
                flex: 4,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.8, // Taller to fit code below QR
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: _buildQrContent(kiosk),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrContent(KioskProvider kiosk) {
    if (kiosk.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kiosk.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Error: ${kiosk.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
               onPressed: _fetchCode, 
               icon: const Icon(Icons.refresh),
               label: const Text('Reintentar')
            )
          ],
        ),
      );
    }

    if (kiosk.linkCode != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code (Optional now, but good for quick scan if we add camera to web)
          Expanded(
            child: QrImageView(
              data: kiosk.linkCode!,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // The CODE Text
          const Text(
            "CÓDIGO DE VINCULACIÓN",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            kiosk.linkCode!,
            style: const TextStyle(
              fontSize: 48, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 8,
              fontFamily: 'Courier', // Monospace for easier reading
              color: Colors.black87
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Countdown Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _secondsRemaining / _totalSeconds,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _secondsRemaining < 60 ? Colors.redAccent : Colors.blueAccent
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  "Expira en ${_formatTime(_secondsRemaining)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        ],
      );
    } 
    
    return const Center(child: Text("Iniciando..."));
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
