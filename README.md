# Railquill

Modern Rails 8.0 blog engine with static site generation.

Railquill is a Ruby on Rails application that pairs a simple writing workflow with static site generation. It’s a good fit if you want to write in Markdown, preview your drafts, manage posts through an admin, and publish a fast static site.

[![Ruby Version](https://img.shields.io/badge/Ruby-3.4%2B-red.svg)](https://ruby-lang.org/)
[![Rails Version](https://img.shields.io/badge/Rails-8.0.2-red.svg)](https://rubyonrails.org/)
[![Docker Support](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://docker.com/)

## Features

### Core
- Markdown-first writing with live preview
- Static site generation to plain HTML
- Dual admin: modern dashboard and ActiveAdmin
- SEO helpers: meta tags, Open Graph, structured data, sitemap
- Draft previews via private URLs
- App manifest; optional service worker (disabled by default)

### Technical
- Rails 8.0.2 (Propshaft, Importmaps)
- Hotwire (Turbo, Stimulus)
- Tailwind CSS
- PostgreSQL
- Dockerized development and deploy
- Rack::Attack-based rate limiting
- Test suite for services and rendering

### Writing
- EasyMDE editor with useful toolbar
- Live preview with Rouge syntax highlighting
- Auto reading time and excerpts
- SEO fields: meta description and featured image
- Drafts with preview before publish

## Quick Start

### Prerequisites
- Ruby 3.4+
- PostgreSQL 14+
- Bundler installed (`gem install bundler`)
  
Note: Node.js is not required (assets use `tailwindcss-rails` and importmaps).

### Local Development

```bash
# Clone the repository
git clone https://github.com/bucky0112/railquill.git
cd railquill

# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Start the development server (Rails + Tailwind CSS watcher)
bin/dev
```

Visit:
- **Blog**: http://localhost:3000
- **Modern Admin**: http://localhost:3000/admin_dashboard
- **Classic Admin**: http://localhost:3000/admin

**Default Admin Credentials:**
- Email: `admin@example.com`
- Password: `password`

### Docker Development

```bash
# Copy environment template
cp .env.docker .env

# Start development environment (Rails + PostgreSQL)
bin/docker-dev start

# Setup database
bin/docker-dev db:setup

# View logs
bin/docker-dev logs

# Stop when done
bin/docker-dev stop
```

## Project Architecture

### Dual Admin System
Railquill features two complementary admin interfaces:

1. **Modern Dashboard** (`/admin_dashboard`)
   - Clean, responsive Tailwind CSS interface
   - Quick actions and metrics overview
   - Optimized for daily content management

2. **ActiveAdmin Interface** (`/admin/*`)
   - Powerful data management and filtering
   - Bulk operations and advanced features
   - Perfect for complex administrative tasks

### Static Site Generation
```bash
# Generate static site to static_site/ directory
bin/publish

# Static files are optimized for:
# - CDN deployment (Netlify, Vercel, etc.)
# - Fast loading with minimal JavaScript
# - SEO optimization with proper meta tags
```

### Key Models & Services

- **Post**: Core content with auto-slug, reading time, word count
- **MarkdownRenderer**: Redcarpet + Rouge syntax highlighting
- **StaticSiteGenerator**: Renders ERB templates to static HTML
- **SecurityMonitor**: Helpers for rate limiting and monitoring

## Development Commands

### Essential
```bash
# Development server with asset watching
bin/dev

# Rails console
bin/rails console

# Run tests
bin/rails test

# Generate static site
bin/publish

# Code quality checks
bin/rubocop
bin/brakeman
```

### Docker
```bash
# Full development environment
bin/docker-dev start

# Rails commands in Docker
bin/docker-dev rails console
bin/docker-dev rails generate model Article

# Database operations
bin/docker-dev db:reset
bin/docker-dev db:migrate

# Shell access
bin/docker-dev shell
```

## Database Schema

### Posts
| Column | Type | Description |
|--------|------|-------------|
| `title` | string | Post title |
| `slug` | string | URL-friendly identifier (auto-generated) |
| `body_md` | text | Markdown content |
| `status` | enum | `draft` (0) or `published` (1) |
| `published_at` | datetime | Publication timestamp |
| `excerpt` | string | Auto-generated summary (160 chars) |
| `meta_description` | string | SEO description |
| `featured_image_url` | string | Header image URL |
| `reading_time` | integer | Auto-calculated (200 WPM) |
| `word_count` | integer | Auto-calculated word count |

**Indexes**: `slug` (unique), `published_at`, `[status, published_at]`

## Customization

### Styling
- **Tailwind CSS** configuration in `config/tailwind.config.js`
- **Custom ActiveAdmin** styles in `app/assets/stylesheets/active_admin.css`
- **Frontend templates** in `app/views/static/`

### Markdown Rendering
- **Custom renderer** in `app/services/markdown_renderer.rb`
- **Syntax highlighting** with Rouge gem
- **Configurable** extensions (tables, strikethrough, etc.)

### Static Site Templates
- **ERB templates** in `app/views/static/`
- **Layout customization** in `app/views/layouts/static.html.erb`
- **SEO meta tags** with structured data

## Security

### Built-in
- Rack::Attack throttling for admin endpoints
- CSRF protection on all forms
- Sanitize for HTML content
- Security headers
- Brakeman scanner

## Deployment

### Production Requirements
- Ruby 3.4+
- PostgreSQL 14+
- Web server (Nginx recommended)

Notes:
- Background jobs use Solid Queue (database-backed). Redis is optional if you choose to use it for caching.

### Docker Deployment
```bash
# Build production image
docker build -t railquill .

# Run with environment variables
docker run -e RAILS_MASTER_KEY=your_key \
           -e DATABASE_URL=postgresql://... \
           -e REDIS_URL=redis://... \
           -p 3000:3000 railquill
```

### Static Site Deployment
```bash
# Generate static files
bin/publish

# Deploy static_site/ directory to:
# - Netlify
# - Vercel  
# - GitHub Pages
# - Any static host
```

### Kamal Deployment
Railquill includes Kamal configuration for Docker-based deployment:

```bash
# Setup deployment
bundle exec kamal setup

# Deploy updates
bundle exec kamal deploy
```

## Testing

### Test Suite
```bash
# Run all tests
bin/rails test

# System tests with browser automation
bin/rails test:system

# Security scan
bin/brakeman

# Code style check
bin/rubocop
```

### Coverage
- Service tests for Markdown and static rendering
- Model, controller, integration, and system tests
- Security checks for rate limiting

## Contributing

We welcome contributions! Please see our contributing guidelines:

### Development Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bin/rails test`)
5. Run security scanner (`bin/brakeman`)
6. Check code style (`bin/rubocop`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

### Code Standards
- Follow Rails conventions and best practices
- Write comprehensive tests for new features
- Maintain security standards
- Update documentation for user-facing changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with excellent open source tools:
- [Ruby on Rails 8.0](https://rubyonrails.org/) - The web framework
- [Hotwire](https://hotwired.dev/) - Modern web interactions  
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first styling
- [ActiveAdmin](https://activeadmin.info/) - Administrative interface
- [Redcarpet](https://github.com/vmg/redcarpet) - Markdown processing
- [Rouge](https://rouge.jneen.net/) - Syntax highlighting

## Support

- Issues: report bugs or request features via GitHub Issues
- Discussions: use GitHub Discussions for help and ideas
