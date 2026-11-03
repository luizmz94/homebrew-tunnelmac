cask "tunnelmac" do
  arch arm: "arm64", intel: "x86_64"

  version "1.3.2"
  sha256 arm:   "df1fcad4c8282d3af2f4b6fb1bbe6d3aa2ab9e667c5bd7d40fa898964cb51147",
         intel: "b0f49ff567b4c0584ceb7eaf8dca487a16f10358050d20c3e0b775a938548cdf"

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

  # Homebrew quits the app (it asks first when VPNs are active) and reopens it after
  # an upgrade; the script waits for that quit and the VPN cleanup to finish.
  uninstall quit:   "com.luiz.vpngui",
            script: {
              executable:   "#{appdir}/TunnelMac.app/Contents/MacOS/VPNGUI",
              args:         ["--wait-for-quit"],
              must_succeed: true,
            }

  caveats <<~EOS
    Open TunnelMac and follow the setup guide.
    Before brew uninstall, use Configurações… > Serviço privilegiado > Remover serviço.
  EOS
end
