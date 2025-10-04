# F-Droid Distribution Guide for KeyMatch

## Overview

This guide covers different approaches to distribute KeyMatch on F-Droid, including options for private repositories.

## Repository Privacy Options

### Option 1: Make Repository Public (Recommended for Official F-Droid)

**Pros:**
- Can submit to official F-Droid repository
- Maximum visibility and user trust
- Automatic updates through F-Droid

**Cons:**
- Source code is publicly visible
- May expose proprietary algorithms or business logic

**Steps:**
1. Go to your GitHub repository settings
2. Scroll down to "Danger Zone"
3. Click "Change repository visibility"
4. Select "Make public"
5. Follow the official F-Droid submission process below

### Option 2: Create Your Own F-Droid Repository (Private Repo Compatible)

**Pros:**
- Keep repository private
- Full control over distribution
- Can still reach F-Droid users
- Can monetize through your own repository

**Cons:**
- Users need to add your repository manually
- Less visibility than official F-Droid
- You handle all updates and maintenance

### Option 3: Hybrid Approach

**Pros:**
- Keep main repository private
- Create a public "release" repository with only the app code
- Submit the public repository to F-Droid

**Cons:**
- More complex setup
- Need to maintain two repositories

## Option 1: Official F-Droid Submission (Public Repository Required)

### Prerequisites

1. **GitHub Account**: You need a GitHub account
2. **Public Repository**: Your code must be in a public GitHub repository
3. **F-Droid Compatible**: App must not use proprietary dependencies
4. **Open Source License**: Must have an open source license

### Step-by-Step Submission Process

#### Step 1: Prepare Your Repository

1. **Make your repository public**:
   - Go to GitHub repository settings
   - Change visibility to "Public"
   - Ensure all code is ready for public viewing

2. **Add F-Droid metadata** (already done):
   - `fdroid-metadata.yml` is already created
   - `README_FDROID.md` is already created

3. **Create a release tag**:
   ```bash
   git tag v1.0.2
   git push origin v1.0.2
   ```

#### Step 2: Fork F-Droid Data Repository

1. **Go to F-Droid Data Repository**:
   - Visit: https://gitlab.com/fdroid/fdroiddata
   - Click "Fork" button

2. **Clone your fork**:
   ```bash
   git clone https://gitlab.com/YOUR_USERNAME/fdroiddata.git
   cd fdroiddata
   ```

#### Step 3: Add Your App Metadata

1. **Create metadata file**:
   ```bash
   # Copy your metadata to the correct location
   cp ../key-match/dating_app/fdroid-metadata.yml metadata/com.keymatch.app.yml
   ```

2. **Update the metadata** with your actual repository details:
   ```yaml
   Categories:
     - Dating
     - Social
     - Internet

   License: MIT

   WebSite: https://keymatch.app

   SourceCode: https://github.com/YOUR_USERNAME/key-match

   IssueTracker: https://github.com/YOUR_USERNAME/key-match/issues

   Donate: https://liberapay.com/keymatch

   Changelog: |
     v1.0.2
     - Added F-Droid compatibility
     - Improved payment system with Stripe and Bitcoin
     - Enhanced user experience and bug fixes

   AutoName: KeyMatch

   Description: |
     KeyMatch is a match making app focused on connections through intelligent matching and detailed profiles.
     
     Features:
     • Create detailed profiles with multiple photos
     • Intelligent matching algorithm
     • Real-time messaging
     • Location-based matching
     • Premium features for enhanced experience
     
     Premium Features (available through Stripe or Bitcoin payments):
     • Unlimited likes
     • Advanced filters
     • Priority support
     • Profile boost
     
     Privacy-focused with no tracking or data selling.

   RepoType: git

   Repo: https://github.com/YOUR_USERNAME/key-match.git

   Builds:
     - versionName: '1.0.2'
       versionCode: 106
       commit: v1.0.2
       subdir: dating_app
       gradle:
         - yes
       preassemble:
         - echo "Building for F-Droid"
       output: build/app/outputs/flutter-apk/app-release.apk
       srclibs:
         - flutter@3.16.9
       rm:
         - nodejs-backend
         - docs
         - scripts
         - test
         - coverage
         - __tests__
         - ios
         - metadata
         - theme
         - collections
         - assets/fonts
         - assets/images
       buildjni:
         - ~/.gradle/caches/transforms-3/*/transformed/flutter_embedding_release

   AutoUpdateMode: Version
   UpdateCheckMode: Tags
   CurrentVersion: 1.0.2
   CurrentVersionCode: 106
   ```

#### Step 4: Test Your Build

1. **Test the build locally** (optional):
   ```bash
   # Install fdroidserver
   pip install fdroidserver

   # Test build
   fdroid build com.keymatch.app
   ```

#### Step 5: Submit Pull Request

1. **Commit your changes**:
   ```bash
   git add metadata/com.keymatch.app.yml
   git commit -m "Add KeyMatch dating app"
   git push origin main
   ```

2. **Create Merge Request**:
   - Go to your fork on GitLab
   - Click "Create merge request"
   - Title: "Add KeyMatch dating app"
   - Description: Include information about your app

3. **Wait for Review**:
   - F-Droid maintainers will review your submission
   - They may request changes or improvements
   - This can take several days to weeks

## Option 2: Create Your Own F-Droid Repository (Private Repo Compatible)

This is the recommended approach for private repositories.

### Step 1: Set Up F-Droid Server

```bash
# Install fdroidserver
pip install fdroidserver

# Initialize F-Droid repository
fdroid init
```

### Step 2: Configure for Private Repository

1. **Create a GitHub Personal Access Token**:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Generate a new token with `repo` scope
   - Copy the token

2. **Configure F-Droid for private access**:
   ```bash
   # Edit config.yml to add your token
   nano config.yml
   ```

   Add your GitHub token:
   ```yaml
   git_credentials:
     - host: github.com
       username: YOUR_GITHUB_USERNAME
       password: YOUR_GITHUB_TOKEN
   ```

### Step 3: Add Your App

```bash
# Add your app metadata
cp fdroid-metadata.yml metadata/com.keymatch.app.yml

# Build your app
fdroid build com.keymatch.app

# Update repository
fdroid update --create-metadata
```

### Step 4: Host Your Repository

#### Option A: GitHub Pages (Free)

1. **Create gh-pages branch**:
   ```bash
   git checkout -b gh-pages
   git push origin gh-pages
   ```

2. **Enable GitHub Pages**:
   - Go to repository settings → Pages
   - Source: Deploy from a branch
   - Branch: gh-pages
   - Your repository will be available at: `https://YOUR_USERNAME.github.io/REPO_NAME`

#### Option B: Netlify (Free)

1. **Deploy to Netlify**:
   ```bash
   # Install Netlify CLI
   npm install -g netlify-cli

   # Deploy
   netlify deploy --prod --dir=repo
   ```

#### Option C: Your Own Server

1. **Upload files to your web server**:
   ```bash
   # Copy repository files to your web server
   scp -r repo/* user@yourserver.com:/var/www/fdroid/
   ```

### Step 5: Share Your Repository

1. **Create a QR code** for easy addition:
   ```bash
   # Install qrencode
   sudo apt install qrencode

   # Generate QR code for your repository
   qrencode -o fdroid-repo-qr.png "https://YOUR_USERNAME.github.io/REPO_NAME/fdroid/repo"
   ```

2. **Share instructions** with users:
   ```
   To add KeyMatch F-Droid repository:
   1. Open F-Droid app
   2. Go to Settings → Repositories
   3. Click the + button
   4. Add: https://YOUR_USERNAME.github.io/REPO_NAME/fdroid/repo
   5. Enable the repository
   6. Search for "KeyMatch" and install
   ```

## Option 3: Hybrid Approach (Recommended for Private Repos)

### Step 1: Create a Public Release Repository

1. **Create a new public repository** (e.g., `keymatch-releases`):
   ```bash
   # Create new repository
   git init keymatch-releases
   cd keymatch-releases
   ```

2. **Copy only the app code**:
   ```bash
   # Copy only the dating_app directory
   cp -r ../key-match/dating_app .
   
   # Add F-Droid metadata
   cp ../key-match/dating_app/fdroid-metadata.yml .
   cp ../key-match/dating_app/README_FDROID.md .
   
   # Create a simple README
   echo "# KeyMatch - Dating App" > README.md
   echo "This is the public release repository for KeyMatch dating app." >> README.md
   ```

3. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Initial release"
   git remote add origin https://github.com/YOUR_USERNAME/keymatch-releases.git
   git push -u origin main
   ```

### Step 2: Submit to F-Droid

Follow the official F-Droid submission process using your public release repository.

## Recommendation

For a private repository, I recommend **Option 2 (Create Your Own F-Droid Repository)** because:

1. **Keeps your code private** while still reaching F-Droid users
2. **Full control** over distribution and updates
3. **Can monetize** through your own repository
4. **Professional appearance** with your own branded repository
5. **No dependency** on F-Droid maintainers for updates

## Next Steps

1. **Choose your preferred option** based on your privacy requirements
2. **Set up your chosen distribution method**
3. **Test the build and distribution process**
4. **Share your repository** with users

Would you like me to help you implement any of these options? 