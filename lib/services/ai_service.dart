import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mcp_config_manager/models/mcp_config.dart';

class AiService {
  static const String _openAiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String _apiKey =
      'OPENAI-API-KEY'; // Replace with your API key in production

  // Generate a description for a configuration
  Future<String> generateConfigDescription(McpConfig config) async {
    try {
      final prompt =
          """I have the following MCP (Model Context Protocol) configuration. 
      Can you provide a brief description (under 100 words) of what this configuration does 
      and what services it connects to?

      ${config.toJsonString(pretty: true)}
      """;

      final response = await _makeOpenAiRequest(prompt);
      return response;
    } catch (e) {
      return 'Error generating description: $e';
    }
  }

  // Suggest improvements for a configuration
  Future<String> suggestImprovements(McpConfig config) async {
    try {
      final prompt =
          """I have the following MCP (Model Context Protocol) configuration. 
      Can you suggest any improvements or additions that might make this configuration more robust 
      or functional? Please keep your suggestions specific and actionable.

      ${config.toJsonString(pretty: true)}
      """;

      final response = await _makeOpenAiRequest(prompt);
      return response;
    } catch (e) {
      return 'Error generating suggestions: $e';
    }
  }

  // Analyze a configuration for potential issues
  Future<String> analyzeConfiguration(McpConfig config) async {
    try {
      final prompt =
          """I have the following MCP (Model Context Protocol) configuration. 
      Please analyze it for any potential issues, security concerns, or best practices that aren't being followed. 
      Format your response as bullet points.

      ${config.toJsonString(pretty: true)}
      """;

      final response = await _makeOpenAiRequest(prompt);
      return response;
    } catch (e) {
      return 'Error analyzing configuration: $e';
    }
  }

  // Generate a custom server configuration based on user input
  Future<Map<String, dynamic>> generateCustomServerConfig(
      String serviceName, String description) async {
    try {
      final prompt =
          """I need to create an MCP (Model Context Protocol) server configuration for a service called "$serviceName". 
      Here's a description of what the service does: "$description"
      
      Based on this information, can you generate a JSON configuration for an MCP server that would work with this service? 
      Include appropriate command, args, and suggested environment variables. 
      
      Format your response as a valid JSON object with this exact structure:
      {
        "command": "string",
        "args": ["string"],
        "env": {"KEY": "description of what this environment variable should contain"}
      }
      """;

      final response =
          await _makeOpenAiRequest(prompt, responseFormat: 'json_object');
      return jsonDecode(response);
    } catch (e) {
      return {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-custom'],
        'env': {'API_KEY': 'Your API key for the service'}
      };
    }
  }

  // Private method to make OpenAI API requests
  Future<String> _makeOpenAiRequest(String prompt,
      {String responseFormat = 'text'}) async {
    final Map<String, dynamic> requestBody = {
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': responseFormat == 'json_object'
              ? 'You are a helpful assistant that responds only with valid JSON objects.'
              : 'You are a helpful assistant specialized in MCP (Model Context Protocol) configurations.'
        },
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
    };

    if (responseFormat == 'json_object') {
      requestBody['response_format'] = {'type': 'json_object'};
    }

    final response = await http.post(
      Uri.parse(_openAiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
          'Failed to get response: ${response.statusCode} ${response.body}');
    }
  }
}
