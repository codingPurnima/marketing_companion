
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../providers/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final LocaleController localeController;

  const ProfileScreen({
    super.key,
    required this.localeController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final publicNameController = TextEditingController();
  final bioController = TextEditingController();
  final craftController = TextEditingController();
  final districtController = TextEditingController();
  final stateController = TextEditingController();
  final whatsappController = TextEditingController();

  bool loading = true;
  bool saving = false;
  String message = '';

  Map<String, String> get authHeaders {
    final token = supabase.auth.currentSession?.accessToken;

    if (token == null) {
      throw Exception('Session expired');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    publicNameController.dispose();
    bioController.dispose();
    craftController.dispose();
    districtController.dispose();
    stateController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/profile/me'),
        headers: authHeaders,
      );

      final data = response.body.isEmpty
          ? null
          : jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception('Profile loading failed');
      }

      if (data is Map) {
        publicNameController.text =
            data['public_name']?.toString() ?? '';
        bioController.text = data['bio']?.toString() ?? '';
        craftController.text = data['craft']?.toString() ?? '';
        districtController.text =
            data['district']?.toString() ?? '';
        stateController.text = data['state']?.toString() ?? '';
        whatsappController.text =
            data['whatsapp_number']?.toString() ?? '';
      }

      if (!mounted) return;

      setState(() {
        message = data == null
            ? l10n.createPublicProfile
            : l10n.profileLoaded;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        message = l10n.profileLoadFailed;
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
      message = '';
    });

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/v1/profile/me'),
        headers: authHeaders,
        body: jsonEncode({
          'public_name': publicNameController.text.trim(),
          'bio': bioController.text.trim(),
          'craft': craftController.text.trim(),
          'district': districtController.text.trim(),
          'state': stateController.text.trim(),
          'whatsapp_number': whatsappController.text.trim(),
        }),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception('Profile saving failed');
      }

      if (!mounted) return;

      setState(() {
        message = l10n.profileSaved;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        message = l10n.profileSaveFailed;
      });
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.fieldRequired;
              }
              return null;
            }
          : null,
    );
  }

  Future<void> shareProfile() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSignInAgain),
        ),
      );
      return;
    }

    if (publicNameController.text.trim().isEmpty ||
        craftController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveBeforeSharing),
        ),
      );
      return;
    }

    final profileUrl = Uri.parse(
      'https://20d50b26.marketing-companion.pages.dev/',
    ).replace(
      queryParameters: {'artisan': userId},
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: l10n.shareProfileTitle,
          text: '${l10n.shareProfileText}\n$profileUrl',
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shareFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            onPressed: loading ? null : shareProfile,
            icon: const Icon(Icons.share),
            tooltip: l10n.shareProfile,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.languageSettings,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: widget.localeController
                                  .locale.languageCode,
                              decoration: InputDecoration(
                                labelText: l10n.selectLanguage,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text(l10n.english),
                                ),
                                DropdownMenuItem(
                                  value: 'hi',
                                  child: Text(l10n.hindi),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;

                                widget.localeController.setLocale(
                                  Locale(value),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      l10n.publicProfileDetails,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),

                    const SizedBox(height: 8),

                    Text(l10n.profileDescription),

                    const SizedBox(height: 20),

                    _buildField(
                      label: l10n.publicName,
                      controller: publicNameController,
                      required: true,
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: l10n.bio,
                      controller: bioController,
                      minLines: 3,
                      maxLines: 5,
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: l10n.craft,
                      controller: craftController,
                      required: true,
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: l10n.district,
                      controller: districtController,
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: l10n.state,
                      controller: stateController,
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: l10n.whatsappNumber,
                      controller: whatsappController,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: saving ? null : saveProfile,
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l10n.saveProfile),
                    ),

                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SelectableText(message),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
