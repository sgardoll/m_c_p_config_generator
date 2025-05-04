import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mcp_config_manager/models/server_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemplateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/ModelContextProtocol/servers/contents';
  static const String _rawContentBaseUrl =
      'https://raw.githubusercontent.com/ModelContextProtocol/servers/main';
  static const String _lastFetchKey = 'last_templates_fetch';
  static const String _cachedTemplatesKey = 'cached_templates';

  // Fetch templates from GitHub repository
  Future<List<ServerTemplate>> fetchTemplatesFromGitHub() async {
    try {
      // Fetch directory contents to find template files
      final response = await http.get(
        Uri.parse('$_githubApiUrl/templates'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch server templates: ${response.statusCode}');
      }

      final List<dynamic> contents = jsonDecode(response.body);
      List<ServerTemplate> templates = [];

      // Process each template file
      for (var item in contents) {
        if (item['type'] == 'file' && item['name'].endsWith('.json')) {
          final templateResponse =
              await http.get(Uri.parse(item['download_url']));

          if (templateResponse.statusCode == 200) {
            final templateData = jsonDecode(templateResponse.body);
            templates.add(_parseTemplateFromJson(templateData));
          }
        }
      }

      // Add the custom template as the last option
      templates.add(ServerTemplate(
        id: 'custom',
        name: 'Custom Server',
        description: 'Create a custom server configuration',
        command: 'npx',
        defaultArgs: ['-y', '@modelcontextprotocol/server-custom'],
        credentials: [],
        iconName: 'settings',
      ));

      // Cache the templates
      await _cacheTemplates(templates);

      return templates;
    } catch (e) {
      print('Error fetching templates: $e');
      // Return cached templates or default ones if fetch fails
      return await getCachedTemplates();
    }
  }

  // Parse a template from JSON
  ServerTemplate _parseTemplateFromJson(Map<String, dynamic> json) {
    final List<EnvCredential> credentials = [];

    if (json['credentials'] != null) {
      for (var cred in json['credentials']) {
        credentials.add(EnvCredential(
          key: cred['key'],
          displayName: cred['displayName'],
          description: cred['description'],
          isSecret: cred['isSecret'] ?? true,
        ));
      }
    }

    return ServerTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      command: json['command'],
      defaultArgs: List<String>.from(json['defaultArgs']),
      credentials: credentials,
      iconName: json['iconName'] ?? 'code',
    );
  }

  // Cache templates locally
  Future<void> _cacheTemplates(List<ServerTemplate> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert templates to JSON string
      final List<Map<String, dynamic>> templatesJson = templates
          .map((template) => {
                'id': template.id,
                'name': template.name,
                'description': template.description,
                'command': template.command,
                'defaultArgs': template.defaultArgs,
                'credentials': template.credentials
                    .map((cred) => {
                          'key': cred.key,
                          'displayName': cred.displayName,
                          'description': cred.description,
                          'isSecret': cred.isSecret,
                        })
                    .toList(),
                'iconName': template.iconName,
              })
          .toList();

      await prefs.setString(_cachedTemplatesKey, jsonEncode(templatesJson));
      await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching templates: $e');
    }
  }

  // Get cached templates
  Future<List<ServerTemplate>> getCachedTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cachedTemplatesKey);

      if (cachedData != null) {
        final List<dynamic> templatesJson = jsonDecode(cachedData);
        return templatesJson
            .map((json) => _parseTemplateFromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error retrieving cached templates: $e');
    }

    // Return default templates if cache is not available
    return ServerTemplateRepository.templates;
  }

  // Check if templates need to be refreshed (e.g., once a day)
  Future<bool> shouldRefreshTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_lastFetchKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Refresh if last fetch was more than 24 hours ago
      return (now - lastFetch) > (24 * 60 * 60 * 1000);
    } catch (e) {
      return true; // Refresh on error
    }
  }

  // Get the most up-to-date templates (either from cache or GitHub)
  Future<List<ServerTemplate>> getTemplates({bool forceRefresh = false}) async {
    if (forceRefresh || await shouldRefreshTemplates()) {
      return await fetchTemplatesFromGitHub();
    } else {
      return await getCachedTemplates();
    }
  }
}
