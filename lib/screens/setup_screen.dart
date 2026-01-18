import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/kiosk_provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KioskProvider>(context, listen: false).fetchLinkCode();
      // TODO: Start listening to socket for 'linked' event
    });
  }

  @override
  Widget build(BuildContext context) {
    final kiosk = Provider.of<KioskProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'Vincular Kiosco',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Escanea este código QR desde el panel de administración de MedixaLink\npara vincular este dispositivo a tu clínica.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              if (kiosk.linkCode != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: kiosk.linkCode!,
                    version: QrVersions.auto,
                    size: 300.0,
                  ),
                )
              else if (kiosk.isLoading)
                const SizedBox(
                  height: 300, 
                  child: Center(child: CircularProgressIndicator())
                )
              else
                 SizedBox(
                  height: 300, 
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          kiosk.error != null 
                            ? 'Error: ${kiosk.error}' 
                            : 'No se pudo generar el código',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        TextButton(
                           onPressed: () => kiosk.fetchLinkCode(), 
                           child: const Text('Reintentar')
                        )
                      ],
                    )
                  )
                ),
                
               const SizedBox(height: 40),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   borderRadius: BorderRadius.circular(8)
                 ),
                 child: Text(
                   'Device ID: ${kiosk.deviceId ?? "..."}',
                   style: const TextStyle(fontFamily: 'Courier', color: Colors.blueGrey),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
