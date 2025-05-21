import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import './firebase/firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/pack_opening_service.dart';
import 'providers/auth_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/pack_provider.dart';
import 'providers/deck_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/user_sales_screen.dart';
import 'screens/deck_builder_screen.dart';
import 'utils/audio_service.dart';
import 'theme/game_theme.dart';

// Definir el navigatorKey global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase con opciones específicas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar AudioService
  final audioService = AudioService();
  await audioService.initialize();

  runApp(const DragonBallCardApp());
}

class DragonBallCardApp extends StatelessWidget {
  const DragonBallCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicios puros
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ProxyProvider<FirestoreService, PackOpeningService>(
          update: (_, firestoreService, __) => PackOpeningService(),
        ),

        // Providers dependientes
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<CollectionProvider>(
          create: (context) => CollectionProvider(),
        ),
        ChangeNotifierProvider<DeckProvider>(
          create: (context) => DeckProvider(),
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
        navigatorKey: navigatorKey,
        title: 'Dragon Ball Card Collector',
        theme: GameTheme.lightTheme,
        darkTheme: GameTheme.darkTheme,
        themeMode: ThemeMode.system,
        // Rutas de la aplicación
        home: const SplashScreen(),
        routes: {
          UserSalesScreen.routeName: (_) => const UserSalesScreen(),
          DeckBuilderScreen.routeName: (_) => const DeckBuilderScreen(),
        },
      ),
    );
  }
}
