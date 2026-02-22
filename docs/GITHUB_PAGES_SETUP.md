---
layout: default
title: GitHub Pages Setup
nav_order: 99
---

# GitHub Pages Documentation Site
{: .no_toc }

Complete guide to setting up and customizing the GitHub Pages documentation site.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

This project includes a professional documentation site built with:

- **Jekyll** - Static site generator
- **Just the Docs** - Modern documentation theme
- **GitHub Pages** - Free hosting
- **GitHub Actions** - Automated deployment

### Features

✅ Full-text search across all documentation  
✅ Responsive design for mobile and desktop  
✅ Professional theme with AWS branding  
✅ Automatic deployment on push  
✅ Syntax highlighting for code blocks  
✅ Automatic navigation generation  
✅ Table of contents for long pages  
✅ Callout boxes for important information  

---

## Quick Setup

### Automated Setup

```bash
# Run setup script
./scripts/setup-github-pages.sh

# Follow the prompts to:
# 1. Install dependencies
# 2. Configure repository URL
# 3. Enable GitHub Pages
# 4. Test local build
```

### Manual Setup

```bash
# 1. Install Ruby and Bundler
brew install ruby
gem install bundler

# 2. Install dependencies
cd docs
bundle install

# 3. Build site
bundle exec jekyll build

# 4. Serve locally
bundle exec jekyll serve --livereload

# 5. Access at http://localhost:4000
```

---

## Configuration

### Update Site Settings

Edit `docs/_config.yml`:

```yaml
# Site information
title: AWS Control Tower Landing Zone
description: Your description here
url: "https://your-org.github.io"
baseurl: "/your-repo"

# GitHub links
aux_links:
  "View on GitHub":
    - "//github.com/your-org/your-repo"
  "Download":
    - "//github.com/your-org/your-repo/archive/main.zip"

# Footer
footer_content: "Copyright &copy; 2024 Your Organization"
```

### Update Repository URLs

Replace all instances of `your-org/aws-control-tower-landingzone`:

```bash
# Find and replace
find docs -type f -name "*.md" -exec sed -i '' \
  's/your-org\/aws-control-tower-landingzone/YOUR-ORG\/YOUR-REPO/g' {} +
```

---

## Customization

### Add Your Logo

1. Create a logo image (PNG, 200x50px recommended)
2. Save as `docs/assets/images/logo.png`
3. Update `_config.yml`:

```yaml
logo: "/assets/images/logo.png"
favicon_ico: "/assets/images/favicon.ico"
```

### Customize Colors

Edit `docs/assets/css/custom.scss`:

```scss
// Your brand colors
$primary-color: #FF9900;
$secondary-color: #232F3E;
$success-color: #28a745;
$warning-color: #ffc107;
$danger-color: #dc3545;
```

### Add Custom CSS

Add to `docs/assets/css/custom.scss`:

```scss
// Custom styles
.my-custom-class {
  color: $primary-color;
  font-weight: bold;
}
```

---

## Adding Content

### Create New Page

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

### Navigation Hierarchy

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

### Callout Boxes

```markdown
{: .note }
> This is a note

{: .important }
> This is important

{: .warning }
> This is a warning

{: .highlight }
> This is highlighted
```

### Code Blocks

````markdown
```bash
terraform init
terraform apply
```

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```
````

### Tables

```markdown
| Column 1 | Column 2 | Column 3 |
|:---------|:--------:|---------:|
| Left     | Center   | Right    |
```

### Buttons

```markdown
[Get Started](#link){: .btn .btn-primary }
[View on GitHub](url){: .btn }
```

---

## Deployment

### Automatic Deployment

The site automatically deploys when you push to `main`:

1. Make changes to `docs/` directory
2. Commit and push to `main` branch
3. GitHub Actions builds and deploys
4. Site updates in ~2 minutes

### Manual Deployment

```bash
# Trigger workflow manually
gh workflow run github-pages.yml

# Or via GitHub UI:
# Actions → Deploy GitHub Pages → Run workflow
```

### Deployment Status

Check deployment status:

```bash
# View workflow runs
gh run list --workflow=github-pages.yml

# View specific run
gh run view <run-id>
```

---

## Local Development

### Start Development Server

```bash
cd docs
bundle exec jekyll serve --livereload
```

Access at: `http://localhost:4000`

### Build Site

```bash
cd docs
bundle exec jekyll build
```

Output in: `docs/_site/`

### Clean Build

```bash
cd docs
bundle exec jekyll clean
bundle exec jekyll build
```

---

## GitHub Pages Settings

### Enable GitHub Pages

1. Go to repository **Settings**
2. Navigate to **Pages** section
3. Under **Build and deployment**:
   - **Source**: GitHub Actions
4. Save changes

### Custom Domain (Optional)

1. Add CNAME file: `docs/CNAME`
2. Content: `docs.example.com`
3. Configure DNS:
   ```
   CNAME docs.example.com your-org.github.io
   ```

### HTTPS

GitHub Pages automatically provides HTTPS:
- `https://your-org.github.io/your-repo/`
- `https://docs.example.com/` (with custom domain)

---

## Troubleshooting

### Build Fails

```bash
# Check Ruby version
ruby --version  # Should be 2.7+

# Update dependencies
cd docs
bundle update

# Clear cache
bundle exec jekyll clean
```

### Search Not Working

```bash
# Rebuild search index
cd docs
bundle exec jekyll clean
bundle exec jekyll build
```

### Styles Not Applying

```bash
# Clear browser cache
# Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

# Rebuild site
cd docs
bundle exec jekyll clean
bundle exec jekyll build
```

### 404 Errors

Check `baseurl` in `_config.yml`:

```yaml
# For project pages
baseurl: "/your-repo"

# For organization pages
baseurl: ""
```

---

## File Structure

```
docs/
├── _config.yml              # Jekyll configuration
├── Gemfile                  # Ruby dependencies
├── index.md                 # Home page
├── getting-started.md       # Getting started
├── architecture.md          # Architecture docs
├── _layouts/                # Custom layouts
│   └── default.html        # Default layout
├── assets/                  # Static assets
│   ├── css/
│   │   └── custom.scss     # Custom styles
│   ├── images/             # Images
│   │   ├── logo.png       # Site logo
│   │   └── favicon.ico    # Favicon
│   └── js/                 # JavaScript
├── _site/                   # Generated site (gitignored)
└── README_DOCS.md          # Documentation README
```

---

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

---

## Advanced Features

### Custom Layouts

Create custom layout in `docs/_layouts/`:

```html
---
layout: default
---

<div class="custom-layout">
  {{ content }}
</div>
```

### Collections

Add to `_config.yml`:

```yaml
collections:
  guides:
    output: true
    permalink: /:collection/:path/
```

### Plugins

Add to `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-sitemap"
  gem "jekyll-feed"
end
```

### Analytics

Add Google Analytics to `_config.yml`:

```yaml
google_analytics: UA-XXXXXXXXX-X
```

---

## Resources

- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Just the Docs Theme](https://just-the-docs.github.io/just-the-docs/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Markdown Guide](https://www.markdownguide.org/)
- [Liquid Template Language](https://shopify.github.io/liquid/)

---

## Support

For issues with the documentation site:

1. Check [README_DOCS.md](README_DOCS.html)
2. Review Jekyll documentation
3. Check GitHub Actions logs
4. Open an issue on GitHub

---

{: .fs-3 }
**Site URL:** `https://your-org.github.io/your-repo/`  
**Build Time:** ~2 minutes  
**Cost:** Free with GitHub Pages
