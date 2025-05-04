# MCP Server Templates

This directory contains sample templates for Model Context Protocol (MCP) servers. The application dynamically loads server templates from a GitHub repository, allowing for easy updates and additions.

## Template Format

Each template is defined in a JSON file with the following structure:

```json
{
  "id": "service_name",
  "name": "Service Display Name",
  "description": "A brief description of what this service does",
  "command": "command_to_run",
  "defaultArgs": ["arg1", "arg2", "etc"],
  "credentials": [
    {
      "key": "ENV_VAR_NAME",
      "displayName": "User-friendly credential name",
      "description": "Help text explaining what this credential is for",
      "isSecret": true
    }
  ],
  "iconName": "icon_name_from_material_icons"
}
```

### Fields Explanation

- `id`: A unique identifier for the template (should match filename)
- `name`: The display name shown in the UI
- `description`: A brief description of what the server does
- `command`: The command to run the server (e.g., "npx")
- `defaultArgs`: Command arguments as an array of strings
- `credentials`: Array of environment variables needed by the server
  - `key`: Environment variable name
  - `displayName`: User-friendly display name
  - `description`: Help text for the user
  - `isSecret`: Boolean indicating if this is sensitive data
- `iconName`: Material icon name to use (see list below)

## Available Icons

The following icon names can be used in the `iconName` field:

- `code`: For development tools
- `chat`: For communication services
- `assignment`: For project management
- `event_note`: For notes/documents
- `folder`: For file storage
- `folder_open`: For file access
- `memory`: For memory/caching services
- `storage`: For databases
- `merge_type`: For version control
- `search`: For search services
- `video_library`: For media services
- `cloud`: For cloud services
- `cloud_queue`: For cloud APIs
- `forum`: For forums/discussions
- `dashboard`: For dashboards
- `linear_scale`: For timeline tools
- `dashboard_customize`: For customizable tools
- `calendar_today`: For calendar/scheduling
- `email`: For email services
- `payment`: For payment services
- `shopping_bag`: For e-commerce
- `support_agent`: For support tools
- `article`: For content management
- `groups`: For team collaboration
- `text_fields`: For text processing
- `bug_report`: For debugging tools
- `wb_sunny`: For weather services
- `settings`: For custom/general tools

## Contributing New Templates

1. Create a new JSON file with your template definition
2. Ensure all required fields are present
3. Test the template locally
4. Submit a pull request to add your template to the repository

## Icon Guidelines

- Choose an icon that visually represents the service's function
- Prefer standard Material icons for consistency
- Use the `settings` icon for general or custom templates
