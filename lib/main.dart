import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bonvo/config/routes/app_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/firebase_options.dart';
import 'package:bonvo/injection/injection.dart';

// Handler para mensajes FCM cuando la app está cerrada o en background
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // El sistema operativo muestra la notificación automáticamente
}

bool _firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      // En web no hay push ni background handler
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
    }
    // Pruebas locales: flutter build/run --dart-define=USE_EMULATOR=true
    // conecta Auth y Firestore a los emuladores en vez de producción.
    if (const bool.fromEnvironment('USE_EMULATOR')) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    }
    _firebaseReady = true;
  } catch (e) {
    // google-services.json aún no configurado: la app corre en modo UI-preview
    debugPrint('⚠️  Firebase no configurado: $e');
  }

  await configureDependencies();

  if (_firebaseReady) {
    // No se recuerda la sesión: cada vez que se abre la app (o se recarga
    // la página en web) hay que iniciar sesión de nuevo.
    try {
      await getIt<AuthRemoteDataSource>().logout();
    } catch (e) {
      debugPrint('⚠️  No se pudo cerrar la sesión previa: $e');
    }
    getIt<AuthBloc>().add(const AuthStarted());
  }

  runApp(const LoyaltyApp());
}

class LoyaltyApp extends StatelessWidget {
  const LoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_firebaseReady) {
      return MaterialApp(
        title: 'Bonvo',
        theme: AppTheme.lightTheme(),
        debugShowCheckedModeBanner: false,
        home: const _FirebaseSetupScreen(),
      );
    }

    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Bonvo',
        theme: AppTheme.lightTheme(),
        routerConfig: getIt<AppRouter>().router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Pantalla temporal que muestra las instrucciones para configurar Firebase.
class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Configura Firebase',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Para usar la app completa necesitas el archivo google-services.json de tu proyecto Firebase.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              const _Step(
                number: '1',
                text: 'Ve a console.firebase.google.com y crea un proyecto.',
              ),
              const _Step(
                number: '2',
                text:
                    'Agrega una app Android con package name:\ncom.example.fidelizacion_app',
              ),
              const _Step(
                number: '3',
                text:
                    'Descarga google-services.json y ponlo en:\nandroid/app/google-services.json',
              ),
              const _Step(
                number: '4',
                text: 'Reinicia la app con flutter run.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(number,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
