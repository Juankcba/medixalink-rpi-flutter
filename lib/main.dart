import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/kiosk_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KioskProvider()),
      ],
      child: MaterialApp(
        title: 'MedixaLink Kiosk',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006FEE),
            brightness: Brightness.light, 
          ),
          useMaterial3: true,
          fontFamily: 'Roboto', 
        ),
        darkTheme: ThemeData(
           colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006FEE),
            brightness: Brightness.dark, 
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system, 
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final kiosk = Provider.of<KioskProvider>(context);

    if (kiosk.isLoading) {
      return const SplashScreen();
    }

    if (!kiosk.isLinked) {
      return const SetupScreen();
    }

    return const CheckInScreen();
  }
}
