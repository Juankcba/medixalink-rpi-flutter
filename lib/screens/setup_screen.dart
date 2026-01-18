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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Flex(
            direction: isLandscape ? Axis.horizontal : Axis.vertical,
            children: [
              // Info Section
              Expanded(
                flex: isLandscape ? 4 : 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.link, size: 48, color: Colors.blueGrey),
                    const SizedBox(height: 16),
                    const Text(
                      'Vincular Kiosco',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    
                    if (kiosk.isLoading)
                      const CircularProgressIndicator()
                    else if (kiosk.error != null)
                      Column(
                        children: [
                           Text(
                            'Error: ${kiosk.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                             onPressed: _fetchCode, 
                             icon: const Icon(Icons.refresh),
                             label: const Text('Reintentar')
                          )
                        ],
                      )
                    else if (kiosk.linkCode != null)
                      Column(
                         crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "CÓDIGO DE VINCULACIÓN",
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.grey, 
                              letterSpacing: 1.5
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kiosk.linkCode!,
                            style: TextStyle(
                              fontSize: isLandscape ? 64 : 56, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 4,
                              fontFamily: 'Courier',
                              color: Colors.black87
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _secondsRemaining / _totalSeconds,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _secondsRemaining < 60 ? Colors.redAccent : Colors.blueAccent
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Expira en ${_formatTime(_secondsRemaining)}",
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),

                    if (isLandscape) const Spacer(),
                    
                    if (isLandscape)
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
              
              if (isLandscape)
                const SizedBox(width: 40)
              else
                const SizedBox(height: 40),
              
              // QR Code Section
              Expanded(
                flex: 4,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
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
                      child: kiosk.linkCode != null 
                          ? QrImageView(
                              data: kiosk.linkCode!,
                              version: QrVersions.auto,
                              backgroundColor: Colors.white,
                            )
                          : const Center(child: Icon(Icons.qr_code_2, size: 64, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
              
              if (!isLandscape) ...[
                 const SizedBox(height: 20),
                 Text(
                    kiosk.deviceId ?? "...",
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.grey),
                 ),
              ]
            ],
          ),
        ),
      ),
    );
  }



  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
