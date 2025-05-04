import 'package:mcp_config_manager/models/mcp_config.dart';

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
  // This list will now serve as fallback templates and will be updated dynamically
  static final List<ServerTemplate> templates = [
    // Core templates
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
    // Storage templates
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
      iconName: 'memory',
    ),
    ServerTemplate(
      id: 'filesystem',
      name: 'Filesystem',
      description: 'Access and manage files and directories on your device',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-filesystem'],
      credentials: [],
      iconName: 'folder_open',
    ),
    ServerTemplate(
      id: 'postgres',
      name: 'PostgreSQL',
      description: 'Query and interact with PostgreSQL databases',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-postgres'],
      credentials: [
        EnvCredential(
          key: 'DATABASE_URL',
          displayName: 'Database URL',
          description: 'Connection string for your PostgreSQL database',
        ),
      ],
      iconName: 'storage',
    ),
    // Development tools
    ServerTemplate(
      id: 'git',
      name: 'Git',
      description: 'Manage Git repositories, commits, branches, and more',
      command: 'uvx',
      defaultArgs: ['mcp-server-git'],
      credentials: [],
      iconName: 'merge_type',
    ),
    // Utility templates
    ServerTemplate(
      id: 'brave_search',
      name: 'Brave Search',
      description: 'Web and local search using Brave\'s Search API',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-brave-search'],
      credentials: [
        EnvCredential(
          key: 'BRAVE_API_KEY',
          displayName: 'Brave API Key',
          description: 'API key for Brave Search',
        ),
      ],
      iconName: 'search',
    ),
    ServerTemplate(
      id: 'youtube',
      name: 'YouTube',
      description: 'Extract YouTube video information and manage content',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-youtube'],
      credentials: [
        EnvCredential(
          key: 'YOUTUBE_API_KEY',
          displayName: 'YouTube API Key',
          description: 'API key for YouTube Data API access',
        ),
      ],
      iconName: 'video_library',
    ),
    ServerTemplate(
      id: 'weather',
      name: 'Weather',
      description: 'Get weather information and forecasts',
      command: 'npx',
      defaultArgs: ['-y', 'mcp_weather'],
      credentials: [],
      iconName: 'wb_sunny',
    ),
    ServerTemplate(
      id: 'aws_kb',
      name: 'AWS Knowledge Base',
      description:
          'Retrieval from AWS Knowledge Base using Bedrock Agent Runtime',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-aws-kb'],
      credentials: [
        EnvCredential(
          key: 'AWS_ACCESS_KEY_ID',
          displayName: 'AWS Access Key ID',
          description: 'AWS access key for authentication',
        ),
        EnvCredential(
          key: 'AWS_SECRET_ACCESS_KEY',
          displayName: 'AWS Secret Access Key',
          description: 'AWS secret key for authentication',
        ),
        EnvCredential(
          key: 'AWS_REGION',
          displayName: 'AWS Region',
          description: 'AWS region for Bedrock (e.g., us-east-1)',
          isSecret: false,
        ),
      ],
      iconName: 'cloud_queue',
    ),
    // Communication tools
    ServerTemplate(
      id: 'discord',
      name: 'Discord',
      description: 'Interact with Discord channels and messages',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-discord'],
      credentials: [
        EnvCredential(
          key: 'DISCORD_BOT_TOKEN',
          displayName: 'Discord Bot Token',
          description: 'Bot token from Discord Developer Portal',
        ),
      ],
      iconName: 'forum',
    ),
    ServerTemplate(
      id: 'trello',
      name: 'Trello',
      description: 'Manage Trello boards, lists, and cards',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-trello'],
      credentials: [
        EnvCredential(
          key: 'TRELLO_API_KEY',
          displayName: 'Trello API Key',
          description: 'API key from Trello Developer Portal',
        ),
        EnvCredential(
          key: 'TRELLO_TOKEN',
          displayName: 'Trello Token',
          description: 'Token with appropriate permissions',
        ),
      ],
      iconName: 'dashboard',
    ),
    ServerTemplate(
      id: 'linear',
      name: 'Linear',
      description: 'Access and manage Linear issues and projects',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-linear'],
      credentials: [
        EnvCredential(
          key: 'LINEAR_API_KEY',
          displayName: 'Linear API Key',
          description: 'API key from Linear settings',
        ),
      ],
      iconName: 'linear_scale',
    ),
    ServerTemplate(
      id: 'asana',
      name: 'Asana',
      description: 'Manage Asana tasks, projects, and workspaces',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-asana'],
      credentials: [
        EnvCredential(
          key: 'ASANA_ACCESS_TOKEN',
          displayName: 'Asana Access Token',
          description: 'Personal access token from Asana developer console',
        ),
      ],
      iconName: 'dashboard_customize',
    ),
    ServerTemplate(
      id: 'figma',
      name: 'Figma',
      description: 'Access Figma files and designs',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-figma'],
      credentials: [
        EnvCredential(
          key: 'FIGMA_ACCESS_TOKEN',
          displayName: 'Figma Access Token',
          description: 'Personal access token from Figma settings',
        ),
      ],
      iconName: 'dashboard_customize',
    ),
    ServerTemplate(
      id: 'calendar',
      name: 'Google Calendar',
      description: 'Manage events and schedules in Google Calendar',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-calendar'],
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
      iconName: 'calendar_today',
    ),
    ServerTemplate(
      id: 'gmail',
      name: 'Gmail',
      description: 'Access and send emails through Gmail',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-gmail'],
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
      iconName: 'email',
    ),
    // Business & E-commerce
    ServerTemplate(
      id: 'stripe',
      name: 'Stripe',
      description: 'Access Stripe payment data and customers',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-stripe'],
      credentials: [
        EnvCredential(
          key: 'STRIPE_API_KEY',
          displayName: 'Stripe API Key',
          description: 'Secret key from Stripe Dashboard',
        ),
      ],
      iconName: 'payment',
    ),
    ServerTemplate(
      id: 'shopify',
      name: 'Shopify',
      description: 'Access Shopify store, products, and orders',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-shopify'],
      credentials: [
        EnvCredential(
          key: 'SHOPIFY_SHOP_NAME',
          displayName: 'Shopify Shop Name',
          description: 'Your shop name (e.g., mystore.myshopify.com)',
          isSecret: false,
        ),
        EnvCredential(
          key: 'SHOPIFY_ACCESS_TOKEN',
          displayName: 'Shopify Access Token',
          description: 'Admin API access token',
        ),
      ],
      iconName: 'shopping_bag',
    ),
    ServerTemplate(
      id: 'zendesk',
      name: 'Zendesk',
      description: 'Access and manage Zendesk support tickets',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-zendesk'],
      credentials: [
        EnvCredential(
          key: 'ZENDESK_SUBDOMAIN',
          displayName: 'Zendesk Subdomain',
          description: 'Your Zendesk subdomain (e.g., company.zendesk.com)',
          isSecret: false,
        ),
        EnvCredential(
          key: 'ZENDESK_EMAIL',
          displayName: 'Zendesk Email',
          description: 'Email address for authentication',
          isSecret: false,
        ),
        EnvCredential(
          key: 'ZENDESK_API_TOKEN',
          displayName: 'Zendesk API Token',
          description: 'API token from Zendesk admin settings',
        ),
      ],
      iconName: 'support_agent',
    ),
    ServerTemplate(
      id: 'confluence',
      name: 'Confluence',
      description: 'Access and manage Confluence pages and spaces',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-confluence'],
      credentials: [
        EnvCredential(
          key: 'CONFLUENCE_DOMAIN',
          displayName: 'Confluence Domain',
          description: 'Your Confluence domain (e.g., company.atlassian.net)',
          isSecret: false,
        ),
        EnvCredential(
          key: 'CONFLUENCE_EMAIL',
          displayName: 'Confluence Email',
          description: 'Email associated with your Confluence account',
          isSecret: false,
        ),
        EnvCredential(
          key: 'CONFLUENCE_API_TOKEN',
          displayName: 'Confluence API Token',
          description: 'API token for Confluence access',
        ),
      ],
      iconName: 'article',
    ),
    ServerTemplate(
      id: 'microsoft_teams',
      name: 'Microsoft Teams',
      description: 'Interact with Microsoft Teams channels and chats',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-teams'],
      credentials: [
        EnvCredential(
          key: 'MS_APP_ID',
          displayName: 'Microsoft App ID',
          description: 'App ID from Azure Portal',
          isSecret: false,
        ),
        EnvCredential(
          key: 'MS_APP_PASSWORD',
          displayName: 'Microsoft App Password',
          description: 'App secret from Azure Portal',
        ),
      ],
      iconName: 'groups',
    ),
    // Custom template should always be last
    ServerTemplate(
      id: 'custom',
      name: 'Custom Server',
      description: 'Create a custom server configuration',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-custom'],
      credentials: [],
      iconName: 'settings',
    ),
  ];

  // Instance of dynamic templates
  static List<ServerTemplate>? _dynamicTemplates;

  // Update templates with the dynamic ones
  static void updateTemplates(List<ServerTemplate> newTemplates) {
    _dynamicTemplates = newTemplates;
  }

  // Get the currently active templates
  static List<ServerTemplate> get activeTemplates {
    return _dynamicTemplates ?? templates;
  }
}
