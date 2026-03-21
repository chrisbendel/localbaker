# Project: Bread Orders (Rails 8.1.1)

This project is a Ruby on Rails 8.1.1 application for managing bread orders.

## Tech Stack

- **Framework**: Ruby on Rails 8.1.1
- **Language**: Ruby
- **Database**: SQLite3
- **Assets**: Propshaft
- **Frontend**: Turbo + Stimulus (via importmap-rails)
- **Background/Infra**: Solid Queue, Solid Cache, Solid Cable (all DB-backed)
- **Testing**: Minitest (+ Capybara/Selenium for system tests)
- **Lint/Style**: StandardRB
- **Security**: bundler-audit, brakeman
- **Deployment**: fly.io

## Project Ethos

- **Simple UI**: The UI should be as bare bones as possible, utilizing standard HTML elements.
- **Mobile First**: All layouts and design decisions must prioritize mobile users and small screens.
- **Web Standards**: Prioritize native browser features (Flexbox, CSS Grid) over custom components or complex JavaScript.
- **Minimal CSS**: Keep styling lean and work within the constraints of native CSS. Avoid heavy customization in favor of sane defaults and structured layouts.
- **Modular Design**: Leverage Rails partials to keep the UI consistent and easy to maintain as individual components.
- **No Dropdowns**: Avoid complex UI patterns like dropdowns that require extra JavaScript.

## Coding Conventions

- **Style**: Follow StandardRB for Ruby style.
- **Architecture**: Conventional Rails (RESTful controllers, fat models, skinny controllers). Use service objects if needed.
- **Frontend**: Prefer progressive enhancement with Turbo and Stimulus.
- **I18n**: All user-facing strings should use i18n (`config/locales`).
- **Security**: Always use Strong Parameters and avoid N+1 queries using `includes`.

## Development Workflow

- **Setup**: `bundle install && bin/rails db:prepare`
- **Server**: `bin/rails server`
- **Tests**: `bin/rails test`
- **Lint**: `bundle exec standardrb` (use `--fix` to auto-correct)
- **Routes**: `bin/rails routes`
- **Console**: `bin/rails console`

## AI Interaction Guidelines

- Use minimal, well-scoped changes.
- Add or update tests for any behavior changes.
- Keep tooling consistent: use `bin/rails` and `bundle exec`.
- Follow feature branch naming: `feat/...`, `fix/...`, `chore/...`.
- Use conventional commit messages.

## MCP (Model Context Protocol)

To enhance your AI-first workflow, you can add MCP servers to your AI tools (Antigravity or Claude Code). Recommended servers for this project:

- **Rails MCP Server (Ruby)**: Provides comprehensive Rails context (routes, models, schema).
  - Setup: Point your AI client to `bundle exec rails-mcp-server`.
  - Gem: Add `gem "rails-mcp-server"` to your Gemfile.
- **Memory/Knowledge MCP**: Useful for long-term project context.
