## Setting up the Homebrew Tap

To make `brew install --cask hyojoongit/tap/ccquick` work, you need a separate
GitHub repository named `homebrew-tap` under the `hyojoongit` account.

### Steps

1. **Create the repository** on GitHub:
   - Repository name: `homebrew-tap`
   - Owner: `hyojoongit`
   - Make it public
   - The full URL will be: `https://github.com/hyojoongit/homebrew-tap`

2. **Push the formula** to that repo:
   ```bash
   cd /path/to/new/repo
   git init
   mkdir -p Casks
   cp /path/to/ccquick/homebrew-tap/Casks/ccquick.rb Casks/ccquick.rb
   git add .
   git commit -m "Add CCQuick cask formula"
   git remote add origin git@github.com:hyojoongit/homebrew-tap.git
   git push -u origin main
   ```

3. **Test the install**:
   ```bash
   brew tap hyojoongit/tap
   brew install --cask hyojoongit/tap/ccquick
   ```

### Updating for new releases

When you release a new version:

1. Build the DMG: `bash dist.sh`
2. Upload the DMG to a GitHub release tagged `vX.Y.Z`
3. Get the sha256: `shasum -a 256 build/CCQuick-X.Y.Z.dmg`
4. Update `Casks/ccquick.rb` in the `homebrew-tap` repo:
   - Update `version "X.Y.Z"`
   - Update `sha256 "..."`
5. Commit and push to `homebrew-tap`

### How Homebrew Taps work

- `brew tap hyojoongit/tap` clones `https://github.com/hyojoongit/homebrew-tap`
- Homebrew looks for formulas in `Formula/` and casks in `Casks/`
- The tap name is derived from the repo: `homebrew-tap` -> `tap`
