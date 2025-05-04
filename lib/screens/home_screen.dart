import 'package:flutter/material.dart';
import 'package:dreamflow/services/auth_service.dart';
import 'package:dreamflow/services/config_service.dart';
import 'package:dreamflow/screens/auth_screen.dart';
import 'package:dreamflow/screens/server_config_screen.dart';
import 'package:dreamflow/screens/preview_screen.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ConfigService _configService = ConfigService();
  final AuthService _authService = AuthService();
  late AnimationController _listAnimationController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  Future<void> _deleteConfiguration(String configId, String configName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text('Are you sure you want to delete "$configName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _configService.deleteConfiguration(configId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration "$configName" deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light 
          ? const Color(0xFFF5F7FA)
          : const Color(0xFF1A1F24),
      appBar: AppBar(
        title: const Text('MCP Configurations'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Model Context Protocol\n(MCP) Servers',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 32),
              Text(
                'Select a server',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<ConfigurationItem>>(
                stream: _configService.getConfigurations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    );
                  }

                  final configs = snapshot.data ?? [];

                  if (configs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings_ethernet_rounded,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No servers added yet',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Create your first MCP server',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildAddServerButton(context),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...configs.map((config) => _buildServerCard(config, theme)),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _exportCombinedConfig,
                            icon: const Icon(Icons.download),
                            label: const Text('Export Combined Config'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ServerConfigScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        elevation: 4,
      ),
    );
  }

  Widget _buildServerCard(ConfigurationItem config, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PreviewScreen(configId: config.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (config.description.isNotEmpty) ...[  
                        const SizedBox(height: 4),
                        Text(
                          config.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildAddServerButton(context, configId: config.id),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServerConfigScreen(
                            configId: config.id,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _deleteConfiguration(config.id, config.name);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddServerButton(BuildContext context, {String? configId}) {
    final theme = Theme.of(context);
    
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServerConfigScreen(configId: configId),
          ),
        );
      },
      icon: Icon(
        Icons.add,
        color: theme.colorScheme.primary,
        size: 18,
      ),
      label: Text(
        'Add server',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      } else {
        return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  
  Future<void> _exportCombinedConfig() async {
    if (_isExporting) return;
    
    setState(() {
      _isExporting = true;
    });
    
    // Variable to track if dialog is open
    bool isDialogOpen = false;
    
    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text('Generating combined configuration...'),
            ],
          ),
        ),
      );
      isDialogOpen = true;
      
      // Get all configurations
      final configs = await _configService.getAllConfigurations();
      
      if (configs.isEmpty) {
        if (!mounted) return;
        if (isDialogOpen) {
          Navigator.of(context).pop(); // Close loading dialog
          isDialogOpen = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No configurations to export')),
        );
        return;
      }
      
      // Combine all configurations
      final combinedConfig = _configService.combineConfigurations(configs);
      
      // Generate the JSON string
      final prettyJson = combinedConfig.toJsonString(pretty: true);
      print('Generated JSON string, length: ${prettyJson.length}');
      
      if (!mounted) return;
      if (isDialogOpen) {
        Navigator.of(context).pop(); // Close loading dialog
        isDialogOpen = false;
      }
      
      // Share the JSON data directly
      try {
        final result = await Share.share(
          prettyJson,
          subject: 'MCP Configuration Export',
        );
        
        print('Share result: $result');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Combined configuration exported successfully')),
        );
      } catch (e) {
        print('Error sharing configuration: $e');
        throw Exception('Failed to share configuration: $e');
      }
    } catch (e) {
      print('Export error: $e');
      if (!mounted) return;
      
      // Make sure dialog is closed even if there's an error
      if (isDialogOpen) {
        try {
          Navigator.of(context).pop(); // Close loading dialog if open
          isDialogOpen = false;
        } catch (_) {
          // Dialog might not be open, ignore error
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting configuration: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}