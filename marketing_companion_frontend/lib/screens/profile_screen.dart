import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
      throw Exception('Your session has expired. Please sign in again.');
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

      final data = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = data is Map ? data['detail'] : null;
        throw Exception(detail ?? 'Unable to load profile.');
      }

      if (data is Map) {
        publicNameController.text = data['public_name']?.toString() ?? '';
        bioController.text = data['bio']?.toString() ?? '';
        craftController.text = data['craft']?.toString() ?? '';
        districtController.text = data['district']?.toString() ?? '';
        stateController.text = data['state']?.toString() ?? '';
        whatsappController.text = data['whatsapp_number']?.toString() ?? '';
      }

      if (!mounted) return;

      setState(() {
        message = data == null
            ? 'Create your public artisan profile.'
            : 'Your profile is loaded.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = e.toString();
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

      final data = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = data is Map ? data['detail'] : null;
        throw Exception(detail ?? 'Unable to save profile.');
      }

      if (!mounted) return;

      setState(() {
        message = 'Profile saved successfully.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = e.toString();
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
                return '$label is required.';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> shareProfile() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }

    if (publicNameController.text.trim().isEmpty ||
        craftController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save your public profile before sharing it.'),
        ),
      );
      return;
    }

    final profileUrl = Uri.parse(
      'https://20d50b26.marketing-companion.pages.dev/',
    ).replace(queryParameters: {'artisan': userId});

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'My artisan profile',
          text:
              'Explore my handmade products and artisan profile:\n$profileUrl',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to share profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My artisan profile'),
        actions: [
          IconButton(
            onPressed: loading ? null : shareProfile,
            icon: const Icon(Icons.share),
            tooltip: 'Share profile',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Public profile details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These details help customers discover and contact you.',
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Public name',
                      controller: publicNameController,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Bio',
                      controller: bioController,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Craft',
                      controller: craftController,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'District',
                      controller: districtController,
                    ),
                    const SizedBox(height: 16),

                    _buildField(label: 'State', controller: stateController),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'WhatsApp number',
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save profile'),
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
