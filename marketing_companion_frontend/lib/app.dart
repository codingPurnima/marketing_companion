import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/theme.dart';
import 'config/app_config.dart';
import 'controllers/voice_assistant_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/catalog_screen.dart';
import 'screens/login_screen.dart';

class ArtisanApp extends StatefulWidget {
  final LocaleController localeController;

  const ArtisanApp({
    super.key,
    required this.localeController,
  });

  @override
  State<ArtisanApp> createState() => _ArtisanAppState();
}

class _ArtisanAppState extends State<ArtisanApp> {
  late final VoiceAssistantController voiceAssistantController;

  @override
  void initState() {
    super.initState();
    voiceAssistantController = VoiceAssistantController();
  }

  @override
  void dispose() {
    voiceAssistantController.dispose();
    widget.localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.localeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Marketing Companion',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          locale: widget.localeController.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: StreamBuilder<AuthState>(
            stream: supabase.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (supabase.auth.currentSession == null) {
                return const LoginScreen();
              }

              return CatalogScreen(
                voiceAssistantController: voiceAssistantController,
                localeController: widget.localeController,
              );
            },
          ),
        );
      },
    );
  }
}