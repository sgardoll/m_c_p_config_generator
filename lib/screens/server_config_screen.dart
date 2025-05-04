import 'package:flutter/material.dart';
import 'package:dreamflow/models/mcp_config.dart';
import 'package:dreamflow/models/server_template.dart';
import 'package:dreamflow/services/config_service.dart';
import 'package:dreamflow/services/ai_service.dart';
import 'package:dreamflow/screens/preview_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServerConfigScreen extends StatefulWidget {
  final String? configId;

  const ServerConfigScreen({super.key, this.configId});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _configService = ConfigService();
  final _aiService = AiService();
  final _secureStorage = const FlutterSecureStorage();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  ConfigurationItem? _existingConfig;
  McpConfig _mcpConfig = McpConfig.empty();
  ServerTemplate _selectedTemplate = ServerTemplateRepository.templates.first;
  List<TextEditingController> _credentialControllers = [];
  String? _serverKey;
  bool _isLoading = false;
  bool _isCustomServer = false;
  final _commandController = TextEditingController();
  final _argsController = TextEditingController();
  bool _isInitialized = false;

  // Bottom sheet visibility controller
  bool _showCredentialSheet = false;

  // Template categories for better organization
  static const Map<String, String> _categories = {
    'development': 'Development Tools',
    'productivity': 'Productivity',
    'communication': 'Communication',
    'data': 'Data & Storage',
    'integrations': 'Integrations',
    'utility': 'Utilities',
  };

  // Maps each template to a category
  String _getTemplateCategory(String templateId) {
    final Map<String, String> categoryMap = {
      'github': 'development',
      'git': 'development',
      'jira': 'development',
      'asana': 'productivity',
      'linear': 'development',
      'trello': 'productivity',
      'slack': 'communication',
      'discord': 'communication',
      'microsoft_teams': 'communication',
      'gmail': 'communication',
      'notion': 'productivity',
      'confluence': 'productivity',
      'google_drive': 'data',
      'postgres': 'data',
      'filesystem': 'utility',
      'calendar': 'productivity',
      'figma': 'development',
      'stripe': 'integrations',
      'shopify': 'integrations',
      'zendesk': 'integrations',
      'brave_search': 'utility',
      'youtube': 'integrations',
      'aws_kb': 'data',
      'weather': 'utility',
      'memory': 'utility',
      'prompts': 'utility',
      'inspector': 'development',
      'weather_tool': 'utility',
      'python_custom': 'development',
    };

    return categoryMap[templateId] ?? 'utility';
  }

  // Filtered list of templates based on search query
  List<ServerTemplate> _filteredTemplates = [];
  String _searchQuery = '';
  String _selectedCategory = '';

  void _filterTemplates(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _updateFilteredTemplates();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = ''; // Toggle off if already selected
      } else {
        _selectedCategory = category;
      }
      _updateFilteredTemplates();
    });
  }

  void _updateFilteredTemplates() {
    _filteredTemplates = ServerTemplateRepository.templates.where((template) {
      // Skip the custom template for filtering
      if (template.id == 'custom') return false;

      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          template.name.toLowerCase().contains(_searchQuery) ||
          template.description.toLowerCase().contains(_searchQuery) ||
          template.id.toLowerCase().contains(_searchQuery);

      // Filter by category
      bool matchesCategory = _selectedCategory.isEmpty ||
          _getTemplateCategory(template.id) == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    // Add custom template at the end if we're not filtering by category
    if (_selectedCategory.isEmpty &&
        (_searchQuery.isEmpty ||
            'custom'.contains(_searchQuery) ||
            'custom server'.contains(_searchQuery))) {
      _filteredTemplates.add(ServerTemplateRepository.templates.last);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _updateFilteredTemplates(); // Initialize filtered templates
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    for (var controller in _credentialControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.configId != null) {
        final config = await _configService.getConfiguration(widget.configId!);
        if (config != null) {
          _existingConfig = config;
          _nameController.text = config.name;
          _descriptionController.text = config.description;
          _mcpConfig = config.configData;

          // Load credentials from secure storage
          if (_mcpConfig.mcpServers.isNotEmpty) {
            final entry = _mcpConfig.mcpServers.entries.first;
            _serverKey = entry.key;
            _loadServerTemplate(entry.key, entry.value);
          }
        }
      } else {
        // Initialize for new configuration
        _initializeCredentialControllers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    }
  }

  void _loadServerTemplate(String serverKey, McpServer server) {
    // Find matching template or use custom
    bool foundTemplate = false;
    for (var template in ServerTemplateRepository.templates) {
      if (template.command == server.command &&
          template.defaultArgs.toString() == server.args.toString()) {
        _selectedTemplate = template;
        _isCustomServer = template.id == 'custom';
        foundTemplate = true;
        break;
      }
    }

    if (!foundTemplate) {
      // Use custom template
      _selectedTemplate = ServerTemplateRepository.templates.last;
      _isCustomServer = true;
      _commandController.text = server.command;
      _argsController.text = server.args.join(' ');
    }

    _initializeCredentialControllers();

    // Load credentials from secure storage
    _loadCredentials(serverKey);
  }

  void _initializeCredentialControllers() {
    // Clean up existing controllers
    for (var controller in _credentialControllers) {
      controller.dispose();
    }

    // Create new controllers
    _credentialControllers = List.generate(
      _selectedTemplate.credentials.length,
      (_) => TextEditingController(),
    );

    if (_isCustomServer) {
      _commandController.text = _selectedTemplate.command;
      _argsController.text = _selectedTemplate.defaultArgs.join(' ');
    } else {
      // Set default name and description for non-custom templates
      _nameController.text = _selectedTemplate.name;
      _descriptionController.text = _selectedTemplate.description;
    }
  }

  Future<void> _loadCredentials(String serverKey) async {
    try {
      for (int i = 0; i < _selectedTemplate.credentials.length; i++) {
        final credential = _selectedTemplate.credentials[i];
        final value =
            await _secureStorage.read(key: '${serverKey}_${credential.key}');
        if (value != null) {
          _credentialControllers[i].text = value;
        }
      }
    } catch (e) {
      // Silently handle errors loading credentials
    }
  }

  Future<void> _saveCredentials(String serverKey) async {
    try {
      for (int i = 0; i < _selectedTemplate.credentials.length; i++) {
        final credential = _selectedTemplate.credentials[i];
        final value = _credentialControllers[i].text;
        if (value.isNotEmpty) {
          await _secureStorage.write(
              key: '${serverKey}_${credential.key}', value: value);
        }
      }
    } catch (e) {
      // Handle credential saving errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Warning: Unable to securely store credentials')),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare server key if not already set
      final serverKey = _serverKey ?? _selectedTemplate.id;

      // Create environment variables map
      final Map<String, String> env = {};
      for (int i = 0; i < _selectedTemplate.credentials.length; i++) {
        final credential = _selectedTemplate.credentials[i];
        final value = _credentialControllers[i].text.trim();
        if (value.isNotEmpty) {
          env[credential.key] = value;
        }
      }

      // Create or update server config
      McpServer server;
      if (_isCustomServer) {
        // Parse custom args
        final args = _argsController.text
            .trim()
            .split(' ')
            .where((arg) => arg.isNotEmpty)
            .toList();

        server = McpServer(
          command: _commandController.text.trim(),
          args: args,
          env: env,
        );
      } else {
        server = _selectedTemplate.createServer(customEnv: env);
      }

      // Save credentials securely
      await _saveCredentials(serverKey);

      // Update MCP config
      final updatedConfig = _mcpConfig.addServer(serverKey, server);

      // Save to Firestore
      if (widget.configId != null) {
        await _configService.updateConfiguration(
          configId: widget.configId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          configData: updatedConfig,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PreviewScreen(configId: widget.configId!),
            ),
          );
        }
      } else {
        final configId = await _configService.createConfiguration(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          configData: updatedConfig,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PreviewScreen(configId: configId),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateAiSuggestion() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a server name first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _aiService.generateCustomServerConfig(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );

      setState(() {
        _isCustomServer = true;
        _selectedTemplate = ServerTemplateRepository.templates.last;
        _commandController.text = result['command'] ?? 'npx';
        _argsController.text = (result['args'] as List<dynamic>?)
                ?.map((arg) => arg.toString())
                .join(' ') ??
            '';

        // Set up credential controllers
        final envVars = result['env'] as Map<String, dynamic>?;
        if (envVars != null && envVars.isNotEmpty) {
          // Dispose old controllers
          for (var controller in _credentialControllers) {
            controller.dispose();
          }

          // Create new credential templates
          final newCredentials = envVars.entries.map((entry) {
            return EnvCredential(
              key: entry.key,
              displayName: entry.key
                  .split('_')
                  .map((word) => word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                      : '')
                  .join(' '),
              description: entry.value.toString(),
            );
          }).toList();

          _selectedTemplate = ServerTemplate(
            id: 'custom',
            name: 'Custom Server',
            description: 'AI-generated configuration',
            command: _commandController.text,
            defaultArgs: _argsController.text
                .split(' ')
                .where((arg) => arg.isNotEmpty)
                .toList(),
            credentials: newCredentials,
            iconName: 'settings',
          );

          _credentialControllers = List.generate(
            newCredentials.length,
            (_) => TextEditingController(),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI suggestion generated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating suggestion: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectTemplate(ServerTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _isCustomServer = template.id == 'custom';
      _initializeCredentialControllers();

      // Show credential sheet if the template has credentials
      if (template.credentials.isNotEmpty) {
        _showCredentialBottomSheet();
      }
    });
  }

  void _showCredentialBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            _getIconData(_selectedTemplate.iconName),
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configure ${_selectedTemplate.name}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedTemplate.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Credential fields
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (_selectedTemplate.credentials.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Authentication Credentials',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Credentials are stored securely on your device',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildCredentialFields(theme),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Close the bottom sheet
                            Navigator.of(context).pop();
                            // Save the configuration and navigate back
                            _saveConfiguration();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save & Add Server',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && !_isInitialized) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('Server Configuration'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.configId != null ? 'Edit Server' : 'Add New Server'),
        actions: [
          if (_isCustomServer)
            IconButton(
              icon: const Icon(Icons.smart_toy),
              tooltip: 'AI Suggestions',
              onPressed: _generateAiSuggestion,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server template section - now at the top
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a server template',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select from pre-configured templates or customize your own',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search field for server templates
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Search templates...',
                        prefixIcon: Icon(Icons.search,
                            color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: theme.colorScheme.outline),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                      onChanged: _filterTemplates,
                    ),
                    // Category filter chips
                    SizedBox(
                      height: 56,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _categories.entries.map((entry) {
                          final isSelected = _selectedCategory == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8, top: 16),
                            child: FilterChip(
                              label: Text(entry.value),
                              selected: isSelected,
                              onSelected: (_) => _selectCategory(entry.key),
                              backgroundColor: theme.colorScheme.surface,
                              selectedColor: theme.colorScheme.primaryContainer,
                              checkmarkColor: theme.colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Template selection as scrollable list
              Expanded(
                child: _filteredTemplates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching templates',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term or category',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        itemCount: _filteredTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _filteredTemplates[index];
                          final bool isSelected = _selectedTemplate == template;
                          final String category = template.id != 'custom'
                              ? _getTemplateCategory(template.id)
                              : 'utility';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isSelected ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline
                                        .withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                _selectTemplate(template);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                    .withOpacity(0.1)
                                                : theme.colorScheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.outline
                                                      .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Icon(
                                            _getIconData(template.iconName),
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface
                                                    .withOpacity(0.8),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                template.name,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? theme
                                                          .colorScheme.primary
                                                      : theme.colorScheme
                                                          .onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme
                                                          .surfaceVariant,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      _categories[category] ??
                                                          'Utility',
                                                      style: theme
                                                          .textTheme.labelSmall
                                                          ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: theme.colorScheme.primary,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      template.description,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (template.id != 'custom') ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Command: ${template.command} ${template.defaultArgs.join(' ')}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Conditional form fields based on selection
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show name and description for custom servers
                    if (_isCustomServer) ...[
                      Text(
                        'Custom Server Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Server Name',
                          hintText: 'Enter server name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a server name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'Enter server description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commandController,
                        decoration: InputDecoration(
                          labelText: 'Command',
                          hintText: 'npx',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        validator: (value) {
                          if (_isCustomServer &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter a command';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _argsController,
                        decoration: InputDecoration(
                          labelText: 'Arguments (space-separated)',
                          hintText: '-y @modelcontextprotocol/server-custom',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outline),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Bottom buttons
                    Row(
                      children: [
                        if (_selectedTemplate.credentials.isNotEmpty &&
                            !_isCustomServer)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showCredentialBottomSheet,
                              icon: const Icon(Icons.vpn_key),
                              label: const Text('Configure Credentials'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                    color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (_selectedTemplate.credentials.isNotEmpty &&
                            !_isCustomServer)
                          const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveConfiguration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.onPrimary),
                                    ),
                                  )
                                : Text(
                                    widget.configId != null
                                        ? 'Save Changes'
                                        : 'Add Server',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCredentialFields(ThemeData theme) {
    final List<Widget> fields = [];

    for (int i = 0; i < _selectedTemplate.credentials.length; i++) {
      final credential = _selectedTemplate.credentials[i];
      final controller = _credentialControllers[i];

      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: credential.displayName,
              helperText: credential.description,
              helperMaxLines: 2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              prefixIcon: Icon(
                credential.isSecret ? Icons.vpn_key : Icons.info,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            obscureText: credential.isSecret,
          ),
        ),
      );
    }

    return fields;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'chat':
        return Icons.chat;
      case 'assignment':
        return Icons.assignment;
      case 'event_note':
        return Icons.event_note;
      case 'folder':
        return Icons.folder;
      case 'folder_open':
        return Icons.folder_open;
      case 'memory':
        return Icons.memory;
      case 'storage':
        return Icons.storage;
      case 'merge_type':
        return Icons.merge_type;
      case 'search':
        return Icons.search;
      case 'video_library':
        return Icons.video_library;
      case 'cloud':
        return Icons.cloud;
      case 'cloud_queue':
        return Icons.cloud_queue;
      case 'check_circle':
        return Icons.check_circle;
      case 'forum':
        return Icons.forum;
      case 'dashboard':
        return Icons.dashboard;
      case 'linear_scale':
        return Icons.linear_scale;
      case 'dashboard_customize':
        return Icons.dashboard_customize;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'email':
        return Icons.email;
      case 'payment':
        return Icons.payment;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'support_agent':
        return Icons.support_agent;
      case 'article':
        return Icons.article;
      case 'groups':
        return Icons.groups;
      case 'text_fields':
        return Icons.text_fields;
      case 'bug_report':
        return Icons.bug_report;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'settings':
      default:
        return Icons.settings;
    }
  }
}
