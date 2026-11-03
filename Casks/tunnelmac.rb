cask "tunnelmac" do
  arch arm: "arm64", intel: "x86_64"

  version "1.3.0"
  sha256 arm:   "d0fb587a79178d3a8d5500b8422656f57cd612072ad4a534fbb8b85ceb12ee17",
         intel: "efbd822280ed5c4ab39bb717eac434c35672bac54d4ce47854f085b24da72997"

  url "https://github.com/luizmz94/tunnelmac/releases/download/v#{version}/TunnelMac-#{version}-#{arch}.zip"
  name "TunnelMac"
  desc "Native GUI for openfortivpn, OpenVPN, WireGuard, OpenConnect and snx-rs"
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
    use and install only those clients (brew install openfortivpn, openvpn,
    wireguard-go, openconnect and/or snx-rs; the guide shows the command),
    activate its service,
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
