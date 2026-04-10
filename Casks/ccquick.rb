cask "ccquick" do
  version "1.0.0"
  sha256 "ea53b732be6ba41017e0b5c7af0f41833b3aef7494c9c8fae9c8ada38713a3ed"

  url "https://github.com/hyojoongit/ccquick/releases/download/v#{version}/CCQuick-#{version}.dmg"
  name "CCQuick"
  desc "Quick access to Claude Code from anywhere on your Mac"
  homepage "https://github.com/hyojoongit/ccquick"

  depends_on macos: ">= :sequoia"

  app "CCQuick.app"

  zap trash: [
    "~/Library/Application Support/CCQuick",
    "~/Library/Preferences/com.ccquick.app.plist",
    "~/Library/LaunchAgents/com.ccquick.app.plist",
  ]
end
