
import 'package:flutter/material.dart';
import 'package:marketing_companion_frontend/config/app_config.dart';
import 'package:marketing_companion_frontend/controllers/voice_assistant_controller.dart';
import 'package:marketing_companion_frontend/screens/catalog_screen.dart';
import 'package:marketing_companion_frontend/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/theme.dart';

class ArtisanApp extends StatefulWidget {
  const ArtisanApp({super.key});

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artisan Catalog Prototype',
      debugShowCheckedModeBanner: false,
      theme: appTheme, // use centralized theme
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (supabase.auth.currentSession == null) {
            return const LoginScreen();
          }

          return CatalogScreen(
            voiceAssistantController: voiceAssistantController,
          );
        },
      ),
    );
  }
}
