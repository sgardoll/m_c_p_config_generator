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
  
  @override
  void initState() {
    super.initState();
    _loadConfig();
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
    }
  }
  
  Future<void> _loadCredentials(String serverKey) async {
    try {
      for (int i = 0; i < _selectedTemplate.credentials.length; i++) {
        final credential = _selectedTemplate.credentials[i];
        final value = await _secureStorage.read(key: '${serverKey}_${credential.key}');
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
          await _secureStorage.write(key: '${serverKey}_${credential.key}', value: value);
        }
      }
    } catch (e) {
      // Handle credential saving errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Warning: Unable to securely store credentials')),
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
        final args = _argsController.text.trim().split(' ')
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
        _argsController.text = (result['args'] as List<dynamic>?)?. 
            map((arg) => arg.toString())
            .join(' ') ?? '';
        
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
              displayName: entry.key.split('_').map(
                (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : ''
              ).join(' '),
              description: entry.value.toString(),
            );
          }).toList();
          
          _selectedTemplate = ServerTemplate(
            id: 'custom',
            name: 'Custom Server',
            description: 'AI-generated configuration',
            command: _commandController.text,
            defaultArgs: _argsController.text.split(' ')
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Server name section
                Text(
                  'Server Information',
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
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
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
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                
                // Server template section
                Text(
                  'Server Template',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a pre-configured template or customize your own',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                  ),
                  child: DropdownButtonFormField<ServerTemplate>(
                    value: _selectedTemplate,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                    items: ServerTemplateRepository.templates.map((template) {
                      return DropdownMenuItem<ServerTemplate>(
                        value: template,
                        child: Row(
                          children: [
                            Icon(
                              _getIconData(template.iconName),
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(template.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (template) {
                      if (template != null && template != _selectedTemplate) {
                        setState(() {
                          _selectedTemplate = template;
                          _isCustomServer = template.id == 'custom';
                          _initializeCredentialControllers();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedTemplate.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Custom server section
                if (_isCustomServer) ...[  
                  Text(
                    'Custom Server Configuration',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commandController,
                    decoration: InputDecoration(
                      labelText: 'Command',
                      hintText: 'npx',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (_isCustomServer && (value == null || value.trim().isEmpty)) {
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
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Credentials section
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Credentials are stored securely on your device',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildCredentialFields(theme),
                  const SizedBox(height: 32),
                ],
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveConfiguration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
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
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                          ),
                        )
                      : Text(
                          widget.configId != null ? 'Save Changes' : 'Add Server',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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
      case 'settings':
      default:
        return Icons.settings;
    }
  }
}