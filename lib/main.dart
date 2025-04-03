import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/pack_opening_service.dart';
import 'providers/auth_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/pack_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DragonBallCardApp());
}

class DragonBallCardApp extends StatelessWidget {
  const DragonBallCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicios
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        ProxyProvider<FirestoreService, PackOpeningService>(
          update: (_, firestoreService, __) => PackOpeningService(),
        ),

        // Providers
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(),
          update: (_, authService, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<FirestoreService, CollectionProvider>(
          create: (context) => CollectionProvider(),
          update: (_, firestoreService, previous) => previous!,
        ),
        ChangeNotifierProxyProvider2<FirestoreService, PackOpeningService,
            PackProvider>(
          create: (context) => PackProvider(
            context.read<FirestoreService>(),
            context.read<PackOpeningService>(),
          ),
          update: (_, firestoreService, packOpeningService, previous) =>
              previous!..update(firestoreService, packOpeningService),
        ),
      ],
      child: MaterialApp(
        title: 'Dragon Ball Card Collector',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF5722),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF5722),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
