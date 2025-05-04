import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mcp_config_manager/models/mcp_config.dart';
import 'package:mcp_config_manager/services/auth_service.dart';

class ConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get a stream of user's configurations
  Stream<List<ConfigurationItem>> getConfigurations() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('configurations')
        .where('user_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ConfigurationItem(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          configData:
              McpConfig.fromJson(data['config_data'] ?? {'mcpServers': {}}),
          createdAt:
              (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isFavorite: data['is_favorite'] ?? false,
        );
      }).toList();
    });
  }

  // Get a list of all user's configurations
  Future<List<ConfigurationItem>> getAllConfigurations() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection('configurations')
        .where('user_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ConfigurationItem(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        configData:
            McpConfig.fromJson(data['config_data'] ?? {'mcpServers': {}}),
        createdAt:
            (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isFavorite: data['is_favorite'] ?? false,
      );
    }).toList();
  }

  // Combine multiple configurations into a single McpConfig
  McpConfig combineConfigurations(List<ConfigurationItem> configs) {
    final Map<String, McpServer> combinedServers = {};

    // Iterate through all configurations and merge their servers
    try {
      for (final config in configs) {
        if (config.configData.mcpServers.isEmpty) {
          continue; // Skip empty configurations
        }

        config.configData.mcpServers.forEach((key, server) {
          // Skip invalid servers
          if (key.isEmpty) {
            return;
          }

          // If server key already exists, add a suffix to make it unique
          String uniqueKey = key;
          int suffix = 1;
          while (combinedServers.containsKey(uniqueKey)) {
            uniqueKey = '${key}_$suffix';
            suffix++;
          }

          combinedServers[uniqueKey] = server;
        });
      }
    } catch (e) {
      print('Error combining configurations: $e');
      // Return empty config if there's an error
      return McpConfig.empty();
    }

    return McpConfig(mcpServers: combinedServers);
  }

  // Get a single configuration by ID
  Future<ConfigurationItem?> getConfiguration(String configId) async {
    final doc =
        await _firestore.collection('configurations').doc(configId).get();
    if (!doc.exists) {
      return null;
    }

    final data = doc.data()!;
    return ConfigurationItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      configData: McpConfig.fromJson(data['config_data'] ?? {'mcpServers': {}}),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: data['is_favorite'] ?? false,
    );
  }

  // Create a new configuration
  Future<String> createConfiguration({
    required String name,
    required String description,
    required McpConfig configData,
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await _firestore.collection('configurations').add({
      'user_id': userId,
      'name': name,
      'description': description,
      'config_data': configData.toJson(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_favorite': false,
    });

    return docRef.id;
  }

  // Update an existing configuration
  Future<void> updateConfiguration({
    required String configId,
    String? name,
    String? description,
    McpConfig? configData,
    bool? isFavorite,
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final Map<String, dynamic> updateData = {
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (configData != null) updateData['config_data'] = configData.toJson();
    if (isFavorite != null) updateData['is_favorite'] = isFavorite;

    await _firestore
        .collection('configurations')
        .doc(configId)
        .update(updateData);
  }

  // Delete a configuration
  Future<void> deleteConfiguration(String configId) async {
    await _firestore.collection('configurations').doc(configId).delete();
  }
}

class ConfigurationItem {
  final String id;
  final String name;
  final String description;
  final McpConfig configData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  ConfigurationItem({
    required this.id,
    required this.name,
    required this.description,
    required this.configData,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
  });
}
