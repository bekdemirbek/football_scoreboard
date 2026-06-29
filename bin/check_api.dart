import 'dart:convert';
import 'dart:io';

import 'package:football_scoreboard/services/api_service.dart';

Future<void> main() async {
  final apiKey = _readEnvValue('FOOTBALL_DATA_API_KEY');
  final baseUrl =
      _readEnvValue('FOOTBALL_DATA_BASE_URL') ??
      'https://api.football-data.org/v4';

  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln(
      'FOOTBALL_DATA_API_KEY .env dosyasinda yok. Once token ekle.',
    );
    exitCode = 1;
    return;
  }

  final apiService = ApiService(apiKey: apiKey, baseUrl: baseUrl);
  final json = await apiService.fetchRawSample();

  const encoder = JsonEncoder.withIndent('  ');
  stdout.writeln(encoder.convert(json));
}

String? _readEnvValue(String key) {
  final fromProcess = Platform.environment[key];
  if (fromProcess != null && fromProcess.isNotEmpty) return fromProcess;

  final file = File('.env');
  if (!file.existsSync()) return null;

  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex == -1) continue;

    final envKey = trimmed.substring(0, separatorIndex).trim();
    if (envKey != key) continue;

    return trimmed.substring(separatorIndex + 1).trim();
  }

  return null;
}
