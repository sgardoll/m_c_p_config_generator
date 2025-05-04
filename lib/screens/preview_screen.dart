import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dreamflow/models/mcp_config.dart';
import 'package:dreamflow/services/config_service.dart';
import 'package:dreamflow/services/ai_service.dart';
import 'package:share_plus/share_plus.dart';

class PreviewScreen extends StatefulWidget {
  final String configId;

  const PreviewScreen({super.key, required this.configId});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> with SingleTickerProviderStateMixin {
  final ConfigService _configService = ConfigService();
  final AiService _aiService = AiService();
  ConfigurationItem? _config;
  bool _isLoading = true;
  String? _aiAnalysis;
  bool _isAnalyzing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await _configService.getConfiguration(widget.configId);
      setState(() {
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _analyzeConfig() async {
    if (_config == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await _aiService.analyzeConfiguration(_config!.configData);
      setState(() {
        _aiAnalysis = analysis;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing configuration: $e')),
        );
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_config == null) return;

    final prettyJson = _config!.configData.toJsonString(pretty: true);
    await Clipboard.setData(ClipboardData(text: prettyJson));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration copied to clipboard')),
      );
    }
  }

  Future<void> _exportFile() async {
    if (_config == null) return;

    // Show export options dialog
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: const Text('Would you like to export just this configuration or combine all your configurations into a single file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('single'),
            child: const Text('This Configuration Only'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('combined'),
            child: const Text('Combined Configuration'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    // Show loading indicator
    if (!mounted) return;
    final loadingDialog = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(choice == 'single' 
              ? 'Preparing configuration...' 
              : 'Preparing combined configuration...'),
          ],
        ),
      ),
    );

    try {
      // Create the JSON data string
      String jsonData;
      if (choice == 'single') {
        // Export just this configuration
        jsonData = _config!.configData.toJsonString(pretty: true);
        print('Single config prepared, length: ${jsonData.length}');
      } else {
        // Export combined configuration
        final configs = await _configService.getAllConfigurations();
        final combinedConfig = _configService.combineConfigurations(configs);
        jsonData = combinedConfig.toJsonString(pretty: true);
        print('Combined config prepared, length: ${jsonData.length}');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      // Share the text content directly
      try {
        final result = await Share.share(
          jsonData,
          subject: choice == 'combined' ? 'MCP Combined Configuration' : 'MCP Configuration',
        );
        
        print('Share result: $result');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              choice == 'combined' 
                  ? 'Combined configuration exported successfully' 
                  : 'Configuration exported successfully'
            )),
          );
        }
      } catch (e) {
        print('Error sharing data: $e');
        throw Exception('Failed to share configuration: $e');
      }
    } catch (e) {
      print('Export error: $e');
      // Close loading dialog if still showing
      if (mounted) {
        try {
          Navigator.of(context).pop(); // Close loading dialog
        } catch (_) {
          // Dialog might already be closed
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting configuration: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuration Preview')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuration Preview')),
        body: Center(
          child: Text(
            'Configuration not found',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_config!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'JSON Preview'),
            Tab(text: 'Analysis'),
          ],
          labelColor: theme.colorScheme.primary,
          indicatorColor: theme.colorScheme.primary,
          dividerColor: Colors.transparent,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to Clipboard',
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export File',
            onPressed: _exportFile,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJsonPreview(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildJsonPreview() {
    final theme = Theme.of(context);
    final jsonString = _config!.configData.toJsonString(pretty: true);
    final json = const JsonDecoder().convert(jsonString) as Map<String, dynamic>;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1E1E1E) // Dark code background
                : const Color(0xFFF8F9FA), // Light code background
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is your MCP configuration file (mcp_config.json).',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E) // Dark code background
                      : const Color(0xFFF8F9FA), // Light code background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: _buildJsonTree(json, theme, 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonTree(dynamic json, ThemeData theme, int depth) {
    const indentWidth = 20.0;
    const lineHeight = 1.5;

    if (json is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '{',
            style: _getJsonStyle(theme, 'bracket'),
          ),
          ...json.entries.map((entry) {
            final isLast = entry == json.entries.last;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: (depth + 1) * indentWidth),
                    Text(
                      '"${entry.key}": ',
                      style: _getJsonStyle(theme, 'key'),
                    ),
                    Expanded(
                      child: entry.value is Map || entry.value is List
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildJsonTree(entry.value, theme, depth + 1),
                                if (!isLast)
                                  Text(
                                    ',',
                                    style: _getJsonStyle(theme, 'bracket'),
                                  ),
                              ],
                            )
                          : Text(
                              entry.value is String
                                  ? '"${entry.value}"${isLast ? '' : ','} '
                                  : '${entry.value}${isLast ? '' : ','} ',
                              style: _getJsonStyle(
                                  theme, entry.value is String ? 'string' : 'value'),
                            ),
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
          Row(
            children: [
              SizedBox(width: depth * indentWidth),
              Text(
                '}',
                style: _getJsonStyle(theme, 'bracket'),
              ),
            ],
          ),
        ],
      );
    } else if (json is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[',
            style: _getJsonStyle(theme, 'bracket'),
          ),
          ...json.asMap().entries.map((entry) {
            final isLast = entry.key == json.length - 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: (depth + 1) * indentWidth),
                    Expanded(
                      child: entry.value is Map || entry.value is List
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildJsonTree(entry.value, theme, depth + 1),
                                if (!isLast)
                                  Text(
                                    ',',
                                    style: _getJsonStyle(theme, 'bracket'),
                                  ),
                              ],
                            )
                          : Text(
                              entry.value is String
                                  ? '"${entry.value}"${isLast ? '' : ','} '
                                  : '${entry.value}${isLast ? '' : ','} ',
                              style: _getJsonStyle(
                                  theme, entry.value is String ? 'string' : 'value'),
                            ),
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
          Row(
            children: [
              SizedBox(width: depth * indentWidth),
              Text(
                ']',
                style: _getJsonStyle(theme, 'bracket'),
              ),
            ],
          ),
        ],
      );
    }

    return Text(
      json.toString(),
      style: _getJsonStyle(theme, 'value'),
    );
  }

  TextStyle _getJsonStyle(ThemeData theme, String type) {
    final baseStyle = theme.textTheme.bodyMedium!.copyWith(
      fontFamily: 'monospace',
      height: 1.5,
    );

    switch (type) {
      case 'key':
        return baseStyle.copyWith(color: theme.colorScheme.primary);
      case 'string':
        return baseStyle.copyWith(color: theme.colorScheme.tertiary);
      case 'value':
        return baseStyle.copyWith(color: theme.colorScheme.secondary);
      case 'bracket':
        return baseStyle.copyWith(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[800],
        );
      default:
        return baseStyle;
    }
  }

  Widget _buildAnalysisTab() {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Configuration Analysis',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get an expert review of your configuration file',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _aiAnalysis == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isAnalyzing) ...[  
                          const CircularProgressIndicator(),
                          const SizedBox(height: 24),
                          Text(
                            'Analyzing your configuration...',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ] else ...[  
                          Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No analysis available yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click the button below to analyze your configuration',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _analyzeConfig,
                            icon: const Icon(Icons.analytics),
                            label: const Text('Analyze Configuration'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: theme.colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Analysis Results',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _aiAnalysis!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}