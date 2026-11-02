cask "tunnelmac" do
  arch arm: "arm64", intel: "x86_64"

  version "1.1.0"
  sha256 arm:   "1572dc0e43771dd427becad0feb8cf0aefd190c883742ec2060dbee1daa8cc9c",
         intel: "a6f81b326abfaca154a59ebedfa52b6e27c6803a278ab71d641af5f238b2480d"

  url "https://github.com/luizmz94/tunnelmac/releases/download/v#{version}/TunnelMac-#{version}-#{arch}.zip"
  name "TunnelMac"
  desc "Native GUI for openfortivpn, OpenVPN, WireGuard and OpenConnect"
  homepage "https://github.com/luizmz94/tunnelmac"

  livecheck do
    url :url
    strategy :github_releases do |json|
      json.filter_map do |release|
        next if release["draft"]

        release["tag_name"][/\Av?(\d+\.\d+\.\d+(?:-rc\.\d+)?)\z/i, 1]
      end
    end
  end

  # Updates itself in the app (Sparkle); brew upgrade stays possible.
  auto_updates true
  depends_on macos: :ventura

  app "TunnelMac.app"

  preflight_steps do
    if_path_exists "OpenFortiDesk.app", base: :appdir do
      # Homebrew runs this in its sandbox: read-only, requires the old service removed.
      run "TunnelMac.app/Contents/MacOS/VPNGUI",
          args:         ["--prepare-for-legacy-migration"],
          base:         :staged_path,
          sudo:         false,
          must_succeed: true
      move "OpenFortiDesk.app", "~/Library/Application Support/VPNGUI/Backups/OpenFortiDesk-before-TunnelMac.app",
           source_base: :appdir,
           overwrite:   false
    end
    if_path_exists "VPNGUI.app", base: :appdir do
      # Homebrew runs this in its sandbox: read-only, requires the old service removed.
      run "TunnelMac.app/Contents/MacOS/VPNGUI",
          args:         ["--prepare-for-legacy-migration"],
          base:         :staged_path,
          sudo:         false,
          must_succeed: true
      move "VPNGUI.app", "~/Library/Application Support/VPNGUI/Backups/VPNGUI-before-TunnelMac.app",
           source_base: :appdir,
           overwrite:   false
    end
  end

  # In Homebrew's sandbox: refuses while the app runs, keeps the registration.
  uninstall_preflight_steps do
    run "TunnelMac.app/Contents/MacOS/VPNGUI",
        args:         ["--prepare-for-maintenance"],
        base:         :appdir,
        sudo:         false,
        must_succeed: true
  end

  caveats <<~EOS
    First use: open TunnelMac and follow the setup guide. Pick the VPN types you
    use and install only those clients (brew install openfortivpn, openvpn
    and/or wireguard-go; the guide shows the command), activate its service,
    approve it in System Settings and approve each client once.

    Updates: TunnelMac offers new versions and installs them itself
    (Atualizar agora). To use brew upgrade instead, quit TunnelMac with Sair
    first (this disconnects its VPNs). The service registration is kept for
    the upgraded app either way.

    Before brew uninstall: open the app, use Configurações… > Serviço
    privilegiado > Remover serviço, then quit with Sair. Homebrew's sandbox does
    not allow removing the registration.

    Migrating from OpenFortiDesk.app or VPNGUI.app (same product, earlier
    name): remove its service first the same way, quit it, then
    brew uninstall --cask openfortidesk (if installed) before installing.

    Stable release: see the release validation report for supported platforms.
    Profiles, Keychain secrets and the protected runtime survive uninstall. Do not
    reopen the app during an upgrade. See SECURITY.md before removing managed root
    files.
  EOS
end
