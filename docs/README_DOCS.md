# Documentation Site - Setup Guide

This directory contains the GitHub Pages documentation site for the AWS Control Tower Landing Zone project.

## Overview

The documentation site is built using:
- **Jekyll** - Static site generator
- **Just the Docs** - Professional documentation theme
- **GitHub Pages** - Free hosting
- **GitHub Actions** - Automated deployment

## Features

- 🔍 **Full-text search** across all documentation
- 📱 **Responsive design** for mobile and desktop
- 🎨 **Professional theme** with AWS branding
- 🚀 **Automatic deployment** on push to main
- 📊 **Syntax highlighting** for code blocks
- 🔗 **Automatic navigation** generation
- 📑 **Table of contents** for long pages
- 🏷️ **Callout boxes** for important information

## Local Development

### Prerequisites

```bash
# Install Ruby (macOS)
brew install ruby

# Install Ruby (Ubuntu)
sudo apt-get install ruby-full

# Install Bundler
gem install bundler
```

### Setup

```bash
# Navigate to docs directory
cd docs

# Install dependencies
bundle install
```

### Run Locally

```bash
# Start Jekyll server
bundle exec jekyll serve

# Or with live reload
bundle exec jekyll serve --livereload

# Access at http://localhost:4000
```

### Build Site

```bash
# Build static site
bundle exec jekyll build

# Output will be in docs/_site/
```

## Project Structure

```
docs/
├── _config.yml              # Jekyll configuration
├── Gemfile                  # Ruby dependencies
├── index.md                 # Home page
├── getting-started.md       # Getting started guide
├── _layouts/                # Custom layouts
│   └── default.html        # Default layout
├── assets/                  # Static assets
│   ├── css/
│   │   └── custom.scss     # Custom styles
│   ├── images/             # Images and icons
│   └── js/                 # JavaScript files
├── ARCHITECTURE.md          # Architecture docs
├── DEPLOYMENT_GUIDE.md      # Deployment guide
├── SECURITY.md              # Security docs
└── ... (other markdown files)
```

## Adding New Pages

### 1. Create Markdown File

Create a new `.md` file in the `docs/` directory:

```markdown
---
layout: default
title: My New Page
nav_order: 5
parent: Getting Started
---

# My New Page

Content goes here...
```

### 2. Front Matter Options

```yaml
---
layout: default           # Layout to use
title: Page Title        # Page title
nav_order: 5             # Navigation order
parent: Parent Page      # Parent page (for hierarchy)
has_children: true       # Has child pages
has_toc: true           # Show table of contents
permalink: /custom-url/  # Custom URL
---
```

### 3. Navigation Hierarchy

```markdown
# Parent page
---
title: Parent
nav_order: 1
has_children: true
---

# Child page
---
title: Child
parent: Parent
nav_order: 1
---

# Grandchild page
---
title: Grandchild
parent: Child
grand_parent: Parent
---
```

## Styling

### Callout Boxes

```markdown
{: .note }
> This is a note callout

{: .important }
> This is an important callout

{: .warning }
> This is a warning callout

{: .highlight }
> This is a highlight callout
```

### Text Formatting

```markdown
{: .fs-9 }
Extra large text

{: .fs-6 .fw-300 }
Large text with light weight

{: .text-delta }
Delta text (for TOC headers)

{: .no_toc }
Exclude from table of contents
```

### Buttons

```markdown
[Get Started](#link){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](url){: .btn .fs-5 .mb-4 .mb-md-0 }
```

### Code Blocks

````markdown
```bash
# Bash code
terraform init
```

```hcl
# Terraform code
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```

```python
# Python code
def hello():
    print("Hello, World!")
```
````

### Tables

```markdown
| Column 1 | Column 2 | Column 3 |
|:---------|:--------:|---------:|
| Left     | Center   | Right    |
| aligned  | aligned  | aligned  |
```

## Custom Styles

Custom CSS is in `assets/css/custom.scss`:

```scss
// Custom colors
$aws-orange: #FF9900;
$aws-dark: #232F3E;

// Custom classes
.feature-grid { ... }
.status-badge { ... }
.architecture-diagram { ... }
```

## Icons and Emojis

Use emojis for visual elements:

```markdown
🚀 Features
📚 Documentation
🔒 Security
💰 Cost
📊 Monitoring
🛠️ Tools
✅ Complete
⏳ In Progress
```

## Search Configuration

Search is configured in `_config.yml`:

```yaml
search_enabled: true
search:
  heading_level: 2
  previews: 3
  preview_words_before: 5
  preview_words_after: 10
```

## Deployment

### Automatic Deployment

The site automatically deploys when you push to the `main` branch:

1. Push changes to `docs/` directory
2. GitHub Actions builds the site
3. Site deploys to GitHub Pages
4. Available at: `https://your-org.github.io/aws-control-tower-landingzone/`

### Manual Deployment

```bash
# Trigger manual deployment
gh workflow run github-pages.yml

# Or via GitHub UI:
# Actions → Deploy GitHub Pages → Run workflow
```

## Configuration

### Update Site Settings

Edit `docs/_config.yml`:

```yaml
title: Your Site Title
description: Your site description
url: "https://your-org.github.io"
baseurl: "/your-repo"

# Update GitHub links
aux_links:
  "View on GitHub":
    - "//github.com/your-org/your-repo"
```

### Update Theme Colors

Edit `docs/assets/css/custom.scss`:

```scss
$aws-orange: #FF9900;  // Primary color
$aws-dark: #232F3E;    // Dark color
```

## Troubleshooting

### Build Fails

```bash
# Check Ruby version
ruby --version  # Should be 2.7+

# Update dependencies
bundle update

# Clear cache
bundle exec jekyll clean
```

### Search Not Working

```bash
# Rebuild search index
bundle exec jekyll build

# Check search configuration in _config.yml
```

### Styles Not Applying

```bash
# Clear browser cache
# Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

# Rebuild site
bundle exec jekyll clean
bundle exec jekyll build
```

## Best Practices

1. **Keep URLs stable** - Use `permalink` for important pages
2. **Use descriptive titles** - Clear, concise page titles
3. **Organize with hierarchy** - Use parent/child relationships
4. **Add navigation order** - Use `nav_order` for logical flow
5. **Include TOC** - Add table of contents for long pages
6. **Use callouts** - Highlight important information
7. **Test locally** - Always test before pushing
8. **Optimize images** - Compress images before adding
9. **Write clear content** - Use simple, direct language
10. **Update regularly** - Keep documentation current

## Resources

- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Just the Docs Theme](https://just-the-docs.github.io/just-the-docs/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Markdown Guide](https://www.markdownguide.org/)

## Support

For issues with the documentation site:
1. Check this README
2. Review Jekyll documentation
3. Check GitHub Actions logs
4. Open an issue on GitHub

---

**Last Updated:** 2024-02-22  
**Jekyll Version:** 4.3+  
**Theme:** Just the Docs 0.7+
