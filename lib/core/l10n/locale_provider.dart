import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current language code: 'es' (default) or 'en'.
final localeProvider = StateProvider<String>((ref) => 'es');
