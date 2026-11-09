import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

final supabase = Supabase.instance.client;
