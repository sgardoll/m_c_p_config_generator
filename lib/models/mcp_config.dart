import 'dart:convert';

class McpConfig {
  final Map<String, McpServer> mcpServers;

  McpConfig({required this.mcpServers});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mcpServers'] = mcpServers.map((key, value) => MapEntry(key, value.toJson()));
    return data;
  }

  factory McpConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, McpServer> servers = {};
    if (json['mcpServers'] != null) {
      json['mcpServers'].forEach((key, value) {
        servers[key] = McpServer.fromJson(value);
      });
    }
    return McpConfig(mcpServers: servers);
  }

  String toJsonString({bool pretty = false}) {
    try {
      final data = toJson();
      if (pretty) {
        return JsonEncoder.withIndent('  ').convert(data);
      } else {
        return jsonEncode(data);
      }
    } catch (e) {
      print('Error converting config to JSON string: $e');
      // Fallback implementation if the standard encoder fails
      final Map<String, dynamic> fallbackData = {'mcpServers': {}};
      mcpServers.forEach((key, server) {
        fallbackData['mcpServers'][key] = {
          'command': server.command,
          'args': server.args,
          'env': server.env,
        };
      });
      
      if (pretty) {
        return JsonEncoder.withIndent('  ').convert(fallbackData);
      } else {
        return jsonEncode(fallbackData);
      }
    }
  }

  factory McpConfig.empty() {
    return McpConfig(mcpServers: {});
  }

  McpConfig copyWith({Map<String, McpServer>? mcpServers}) {
    return McpConfig(
      mcpServers: mcpServers ?? Map.from(this.mcpServers),
    );
  }

  McpConfig addServer(String key, McpServer server) {
    final updatedServers = Map<String, McpServer>.from(mcpServers);
    updatedServers[key] = server;
    return McpConfig(mcpServers: updatedServers);
  }

  McpConfig removeServer(String key) {
    final updatedServers = Map<String, McpServer>.from(mcpServers);
    updatedServers.remove(key);
    return McpConfig(mcpServers: updatedServers);
  }
}

class McpServer {
  final String command;
  final List<String> args;
  final Map<String, String> env;

  McpServer({
    required this.command,
    required this.args,
    required this.env,
  });

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'args': args,
      'env': env,
    };
  }

  factory McpServer.fromJson(Map<String, dynamic> json) {
    // Safely convert the environment variables to a Map<String, String>
    final Map<String, String> envMap = {};
    if (json['env'] != null) {
      (json['env'] as Map<dynamic, dynamic>).forEach((key, value) {
        if (key is String) {
          envMap[key] = value?.toString() ?? '';
        }
      });
    }
    
    return McpServer(
      command: json['command'] ?? '',
      args: List<String>.from(json['args'] ?? []),
      env: envMap,
    );
  }

  McpServer copyWith({
    String? command,
    List<String>? args,
    Map<String, String>? env,
  }) {
    return McpServer(
      command: command ?? this.command,
      args: args ?? List.from(this.args),
      env: env ?? Map.from(this.env),
    );
  }
}