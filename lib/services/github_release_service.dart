import 'dart:convert';

import 'package:http/http.dart' as http;

class GitHubReleaseException implements Exception {
  const GitHubReleaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ReleaseMetadataSource {
  Future<List<Map<String, dynamic>>> fetchReleases();
}

class GitHubReleaseService implements ReleaseMetadataSource {
  GitHubReleaseService({http.Client? client})
    : _client = client ?? http.Client();

  static const githubOwner = 'TomasClausen';
  static const githubRepo = 'project-garage';
  static final releasesEndpoint = Uri.https(
    'api.github.com',
    '/repos/$githubOwner/$githubRepo/releases',
    {'per_page': '20'},
  );

  final http.Client _client;

  @override
  Future<List<Map<String, dynamic>>> fetchReleases() async {
    final response = await _client
        .get(
          releasesEndpoint,
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'Project-Garage-Update-Center',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 403 || response.statusCode == 429) {
      throw const GitHubReleaseException(
        'GitHub limitó temporalmente las consultas. Intentá más tarde.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GitHubReleaseException(
        'GitHub respondió con estado ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException();
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } on FormatException {
      throw const GitHubReleaseException(
        'GitHub devolvió información de versión inválida.',
      );
    } on TypeError {
      throw const GitHubReleaseException(
        'GitHub devolvió información de versión inválida.',
      );
    }
  }
}
