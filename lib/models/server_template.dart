import 'package:dreamflow/models/mcp_config.dart';

class ServerTemplate {
  final String id;
  final String name;
  final String description;
  final String command;
  final List<String> defaultArgs;
  final List<EnvCredential> credentials;
  final String iconName;

  ServerTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.command,
    required this.defaultArgs,
    required this.credentials,
    required this.iconName,
  });

  McpServer createServer({Map<String, String>? customEnv}) {
    final Map<String, String> env = {};
    if (customEnv != null) {
      env.addAll(customEnv);
    }
    return McpServer(
      command: command,
      args: List.from(defaultArgs),
      env: env,
    );
  }
}

class EnvCredential {
  final String key;
  final String displayName;
  final String description;
  final bool isSecret;

  EnvCredential({
    required this.key,
    required this.displayName,
    required this.description,
    this.isSecret = true,
  });
}

class ServerTemplateRepository {
  static final List<ServerTemplate> templates = [
    ServerTemplate(
      id: 'github',
      name: 'GitHub',
      description: 'Access GitHub repositories, issues, and pull requests',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-github'],
      credentials: [
        EnvCredential(
          key: 'GITHUB_PERSONAL_ACCESS_TOKEN',
          displayName: 'GitHub Personal Access Token',
          description:
              'Used to authenticate with the GitHub API. Create one at https://github.com/settings/tokens',
        ),
      ],
      iconName: 'code',
    ),
    ServerTemplate(
      id: 'slack',
      name: 'Slack',
      description: 'Interact with Slack channels and messages',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-slack'],
      credentials: [
        EnvCredential(
          key: 'SLACK_BOT_TOKEN',
          displayName: 'Slack Bot Token',
          description:
              'Bot token for Slack API access. Create one at https://api.slack.com/apps',
        ),
        EnvCredential(
          key: 'SLACK_SIGNING_SECRET',
          displayName: 'Slack Signing Secret',
          description: 'Required for verifying requests from Slack',
        ),
      ],
      iconName: 'chat',
    ),
    ServerTemplate(
      id: 'jira',
      name: 'Jira',
      description: 'Manage Jira issues, projects, and workflows',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-jira'],
      credentials: [
        EnvCredential(
          key: 'JIRA_API_TOKEN',
          displayName: 'Jira API Token',
          description: 'API token for Jira access',
        ),
        EnvCredential(
          key: 'JIRA_EMAIL',
          displayName: 'Jira Email',
          description: 'Email associated with your Jira account',
          isSecret: false,
        ),
        EnvCredential(
          key: 'JIRA_DOMAIN',
          displayName: 'Jira Domain',
          description: 'Your Jira domain (e.g., company.atlassian.net)',
          isSecret: false,
        ),
      ],
      iconName: 'assignment',
    ),
    ServerTemplate(
      id: 'notion',
      name: 'Notion',
      description: 'Access and update Notion databases and pages',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-notion'],
      credentials: [
        EnvCredential(
          key: 'NOTION_API_KEY',
          displayName: 'Notion API Key',
          description: 'Integration token from Notion',
        ),
      ],
      iconName: 'event_note',
    ),
    ServerTemplate(
      id: 'google_drive',
      name: 'Google Drive',
      description: 'Search and manage files in Google Drive',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-google-drive'],
      credentials: [
        EnvCredential(
          key: 'GOOGLE_CLIENT_ID',
          displayName: 'Google Client ID',
          description: 'OAuth client ID from Google Cloud Console',
          isSecret: false,
        ),
        EnvCredential(
          key: 'GOOGLE_CLIENT_SECRET',
          displayName: 'Google Client Secret',
          description: 'OAuth client secret from Google Cloud Console',
        ),
        EnvCredential(
          key: 'GOOGLE_REFRESH_TOKEN',
          displayName: 'Google Refresh Token',
          description: 'OAuth refresh token for long-term access',
        ),
      ],
      iconName: 'folder',
    ),
    ServerTemplate(
      id: 'memory',
      name: 'Memory',
      description: 'Provides short-term memory for the AI model',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-memory'],
      credentials: [], // No credentials needed for basic usage
      iconName: 'memory', // Assuming a 'memory' icon exists or will be added
    ),
    ServerTemplate(
      id: 'custom',
      name: 'Custom Server',
      description: 'Configure a custom MCP server',
      command: '',
      defaultArgs: [],
      credentials: [],
      iconName: 'settings',
    ),
  ];

  static ServerTemplate getTemplateById(String id) {
    return templates.firstWhere(
      (template) => template.id == id,
      orElse: () => templates.last, // Return the custom template if not found
    );
  }
}
