import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/routes.dart';
import 'services/storage_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

/// Handler pour les messages Firebase en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurer le handler pour les messages en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialiser SharedPreferences
  await StorageService.init();

  // Initialiser les paramètres
  final settingsService = SettingsService();
  await settingsService.initialize();

  // Initialiser le service de notifications locales
  await NotificationService().initialize();

  // Initialiser FCM (Firebase Cloud Messaging)
  await FcmService().initialize();

  // Initialiser le service de thème
  final themeService = ThemeService();
  await themeService.initialize();

  // Initialiser le service de langue
  final languageService = LanguageService();
  await languageService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: languageService),
      ],
      child: const NoraMarketplaceApp(),
    ),
  );
}

class NoraMarketplaceApp extends StatelessWidget {
  const NoraMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, child) {
        return MaterialApp.router(
          title: 'NORA Marketplace',
          debugShowCheckedModeBanner: false,
          theme: themeService.getTheme(),
          locale: Locale(languageService.currentLanguageCode),
          localizationsDelegates: const [
            // ✅ CORRECTION: Ajoutez ces delegates essentiels
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // Tu peux garder tes propres delegates ici
          ],
          supportedLocales: const [
            Locale('fr', ''),
            Locale('en', ''),
          ],
          routerConfig: AppRoutes.router,
          builder: (context, child) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                
                final router = AppRoutes.router;
                if (router.canPop()) {
                  router.pop();
                  return;
                }
                
                final location = router.routerDelegate.currentConfiguration.uri.path;
                if (location == '/home' || location == '/' || location == '/login') {
                  final exitApp = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Quitter l\'application'),
                        ],
                      ),
                      content: const Text('Voulez-vous vraiment quitter l\'application ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Quitter'),
                        ),
                      ],
                    ),
                  );
                  if (exitApp == true) {
                    SystemNavigator.pop();
                  }
                } else {
                  router.go('/home');
                }
              },
              child: child!,
            );
          },
        );
      },
    );
  }
}