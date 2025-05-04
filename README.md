# MCP Server Configuration Generator

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart Version](https://img.shields.io/badge/dart-3.0%2B-blue)](https://dart.dev/)

A Dart package for generating Model Context Protocol (MCP) server configurations with pre-built templates for popular services.

## Features

- **30+ Pre-configured Templates** - Ready-to-use server configurations for:

  - Cloud Services (AWS, Google, Azure)
  - Collaboration Tools (Slack, Discord, Microsoft Teams)
  - Development Platforms (GitHub, Git, Linear)
  - Productivity Tools (Notion, Asana, Trello)
  - Databases (PostgreSQL)
  - Custom Python/Node.js servers

- **Environment Management** - Secure credential handling with secret masking
- **Cross-Platform** - Works on Windows, macOS, and Linux
- **Extensible Architecture** - Easily add new templates through code

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mcp_config_generator:
    git:
      url: https://github.com/yourusername/mcp_config_generator.git
      ref: main
```

## Quick Start

```dart
import 'package:mcp_config_generator/models/server_template.dart';

void main() {
  // Get GitHub template
  final githubTemplate = ServerTemplateRepository.getTemplateById('github');

  // Create server instance with credentials
  final githubServer = githubTemplate.createServer(
    customEnv: {
      'GITHUB_PERSONAL_ACCESS_TOKEN': 'your_token_here'
    }
  );

  print('''
  GitHub Server Configuration:
  Command: ${githubServer.command}
  Arguments: ${githubServer.args.join(' ')}
  Environment Keys: ${githubServer.env.keys.join(', ')}
  ''');
}
```

## Supported Integrations

| Service              | Template ID     | Credentials | Official Package                        |
| -------------------- | --------------- | ----------- | --------------------------------------- |
| GitHub               | `github`        | 1           | `@modelcontextprotocol/server-github`   |
| Slack                | `slack`         | 2           | `@modelcontextprotocol/server-slack`    |
| PostgreSQL           | `postgres`      | 1           | `@modelcontextprotocol/server-postgres` |
| AWS Knowledge Base   | `aws_kb`        | 3           | `@modelcontextprotocol/server-aws-kb`   |
| Custom Python Server | `python_custom` | 0           | -                                       |
| Custom Server        | `custom`        | 0           | -                                       |

Full list available in [TEMPLATES.md](TEMPLATES.md)

## Security

**Important Credential Handling Notes:**

1. Always store secrets in environment variables
2. Never commit `.env` files to version control
3. Use secret management tools for production:
   - AWS Secrets Manager
   - HashiCorp Vault
   - Azure Key Vault

## Development

### Requirements

- Dart SDK >= 3.0
- MCP Framework

### Building Templates

1. Add new template in `lib/models/server_template.dart`:

```dart
ServerTemplate(
  id: 'new_service',
  name: 'New Service',
  description: 'New service integration',
  command: 'npx',
  defaultArgs: ['-y', '@package/server-new-service'],
  credentials: [
    EnvCredential(
      key: 'API_KEY',
      displayName: 'Service API Key',
      description: 'Obtained from service dashboard',
      isSecret: true
    )
  ],
  iconName: 'new_releases'
);
```

2. Run verification tests:

```bash
dart test
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Add tests for new templates
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.
