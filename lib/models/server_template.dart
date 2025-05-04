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
    ServerTemplate(
      id: 'git',
      name: 'Git',
      description: 'Manage Git repositories, commits, branches, and more',
      command: 'uvx',
      defaultArgs: ['mcp-server-git'],
      credentials: [],
      iconName: 'merge_type',
    ),
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
      iconName: 'cloud',
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
          description: 'AWS secret access key for authentication',
        ),
        EnvCredential(
          key: 'AWS_REGION',
          displayName: 'AWS Region',
          description: 'AWS region for the Knowledge Base',
          isSecret: false,
        ),
      ],
      iconName: 'cloud_queue',
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
          description: 'Personal access token for Asana',
        ),
      ],
      iconName: 'check_circle',
    ),
    ServerTemplate(
      id: 'discord',
      name: 'Discord',
      description: 'Interact with Discord servers, channels, and messages',
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
          description: 'API key from Trello',
        ),
        EnvCredential(
          key: 'TRELLO_TOKEN',
          displayName: 'Trello Token',
          description: 'Authentication token for Trello',
        ),
      ],
      iconName: 'dashboard',
    ),
    ServerTemplate(
      id: 'linear',
      name: 'Linear',
      description:
          'Manage software development tasks, issues and projects in Linear',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-linear'],
      credentials: [
        EnvCredential(
          key: 'LINEAR_API_KEY',
          displayName: 'Linear API Key',
          description: 'API key from Linear',
        ),
      ],
      iconName: 'linear_scale',
    ),
    ServerTemplate(
      id: 'figma',
      name: 'Figma',
      description: 'Access and manage Figma design files and projects',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-figma'],
      credentials: [
        EnvCredential(
          key: 'FIGMA_ACCESS_TOKEN',
          displayName: 'Figma Access Token',
          description: 'Personal access token for Figma API',
        ),
      ],
      iconName: 'dashboard_customize',
    ),
    ServerTemplate(
      id: 'calendar',
      name: 'Calendar',
      description: 'Manage Google Calendar events and schedules',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-calendar'],
      credentials: [
        EnvCredential(
          key: 'CALENDAR_CREDENTIALS',
          displayName: 'Calendar Credentials',
          description: 'JSON credentials for Google Calendar API access',
        ),
      ],
      iconName: 'calendar_today',
    ),
    ServerTemplate(
      id: 'gmail',
      name: 'Gmail',
      description: 'Access and manage Gmail emails and drafts',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-gmail'],
      credentials: [
        EnvCredential(
          key: 'GMAIL_CREDENTIALS',
          displayName: 'Gmail Credentials',
          description: 'JSON credentials for Gmail API access',
        ),
      ],
      iconName: 'email',
    ),
    ServerTemplate(
      id: 'stripe',
      name: 'Stripe',
      description: 'Manage payments, customers, and subscriptions with Stripe',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-stripe'],
      credentials: [
        EnvCredential(
          key: 'STRIPE_API_KEY',
          displayName: 'Stripe API Key',
          description: 'Secret API key from Stripe dashboard',
        ),
      ],
      iconName: 'payment',
    ),
    ServerTemplate(
      id: 'shopify',
      name: 'Shopify',
      description: 'Manage Shopify store, products, orders, and customers',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-shopify'],
      credentials: [
        EnvCredential(
          key: 'SHOPIFY_API_KEY',
          displayName: 'Shopify API Key',
          description: 'API key from Shopify admin',
        ),
        EnvCredential(
          key: 'SHOPIFY_API_SECRET',
          displayName: 'Shopify API Secret',
          description: 'API secret from Shopify admin',
        ),
        EnvCredential(
          key: 'SHOPIFY_STORE_URL',
          displayName: 'Shopify Store URL',
          description: 'Your Shopify store URL (e.g., mystore.myshopify.com)',
          isSecret: false,
        ),
      ],
      iconName: 'shopping_bag',
    ),
    ServerTemplate(
      id: 'zendesk',
      name: 'Zendesk',
      description: 'Manage support tickets and customer service in Zendesk',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-zendesk'],
      credentials: [
        EnvCredential(
          key: 'ZENDESK_EMAIL',
          displayName: 'Zendesk Email',
          description: 'Email address for Zendesk account',
          isSecret: false,
        ),
        EnvCredential(
          key: 'ZENDESK_API_TOKEN',
          displayName: 'Zendesk API Token',
          description: 'API token for Zendesk access',
        ),
        EnvCredential(
          key: 'ZENDESK_SUBDOMAIN',
          displayName: 'Zendesk Subdomain',
          description: 'Your Zendesk subdomain (e.g., company.zendesk.com)',
          isSecret: false,
        ),
      ],
      iconName: 'support_agent',
    ),
    ServerTemplate(
      id: 'confluence',
      name: 'Confluence',
      description: 'Access and manage Atlassian Confluence pages and content',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-confluence'],
      credentials: [
        EnvCredential(
          key: 'CONFLUENCE_EMAIL',
          displayName: 'Confluence Email',
          description: 'Email address for Confluence account',
          isSecret: false,
        ),
        EnvCredential(
          key: 'CONFLUENCE_API_TOKEN',
          displayName: 'Confluence API Token',
          description: 'API token for Confluence access',
        ),
        EnvCredential(
          key: 'CONFLUENCE_DOMAIN',
          displayName: 'Confluence Domain',
          description: 'Your Confluence domain (e.g., company.atlassian.net)',
          isSecret: false,
        ),
      ],
      iconName: 'article',
    ),
    ServerTemplate(
      id: 'microsoft_teams',
      name: 'Microsoft Teams',
      description: 'Interact with Microsoft Teams channels and messages',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-ms-teams'],
      credentials: [
        EnvCredential(
          key: 'MS_CLIENT_ID',
          displayName: 'Microsoft Client ID',
          description: 'Client ID from Microsoft Azure portal',
        ),
        EnvCredential(
          key: 'MS_CLIENT_SECRET',
          displayName: 'Microsoft Client Secret',
          description: 'Client secret from Microsoft Azure portal',
        ),
        EnvCredential(
          key: 'MS_TENANT_ID',
          displayName: 'Microsoft Tenant ID',
          description: 'Tenant ID from Microsoft Azure portal',
          isSecret: false,
        ),
      ],
      iconName: 'groups',
    ),
    ServerTemplate(
      id: 'prompts',
      name: 'Prompt Templates',
      description: 'Generate structured prompts for common tasks',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/server-prompts'],
      credentials: [],
      iconName: 'text_fields',
    ),
    ServerTemplate(
      id: 'inspector',
      name: 'MCP Inspector',
      description: 'Debug and test other MCP servers',
      command: 'npx',
      defaultArgs: ['-y', '@modelcontextprotocol/inspector'],
      credentials: [],
      iconName: 'bug_report',
    ),
    ServerTemplate(
      id: 'weather_tool',
      name: 'Weather Tools',
      description: 'Retrieve weather forecasts and conditions',
      command: 'uvx',
      defaultArgs: ['--directory', '.', 'run', 'weather.py'],
      credentials: [],
      iconName: 'wb_sunny',
    ),
    ServerTemplate(
      id: 'python_custom',
      name: 'Python Server',
      description: 'Run a Python MCP server with UV',
      command: 'uv',
      defaultArgs: ['--directory', '{directory}', 'run', '{script}'],
      credentials: [],
      iconName: 'code',
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
