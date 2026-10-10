{
  lib,
  stdenvNoCC,
  fetchurl,
  patchelf,
  makeWrapper,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  libxkbfile,
  mesa,
  nspr,
  nss,
  pango,
  pipewire,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxshmfence,
  libxtst,
  libsecret,
  libnotify,
  systemd,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  system = stdenvNoCC.hostPlatform.system;
  source = sources.sources.${system} or (throw "helium: no prebuilt binary available for ${system}");

  archDir =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "arm64";
    }
    .${system};
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "helium";
  version = sources.version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = "helium-${finalAttrs.version}-${archDir}_linux";

  nativeBuildInputs = [
    patchelf
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libxkbcommon
    libxkbfile
    mesa
    nspr
    nss
    pango
    pipewire
    libsecret
    libnotify
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxshmfence
    libxtst
  ];

  runtimeDependencies = [
    (lib.getLib systemd)
  ];

  # The Qt shim libraries are only dlopen'd under KDE/Plasma for native Qt
  # file dialogs. They are never used on GTK desktops, so we deliberately do
  # not pull Qt into the closure.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/helium $out/bin
    cp -r . $out/opt/helium/

    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp $out/opt/helium/helium.desktop $out/share/applications/
    cp $out/opt/helium/product_logo_256.png \
      $out/share/icons/hicolor/256x256/apps/helium.png

    makeWrapper $out/opt/helium/helium-wrapper $out/bin/helium \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer" \
      --add-flags "--enable-wayland-ime=true"

    substituteInPlace $out/share/applications/helium.desktop \
      --replace-fail "Exec=helium %U" "Exec=$out/bin/helium %U" \
      --replace-fail "Exec=helium --incognito" "Exec=$out/bin/helium --incognito" \
      --replace-fail "Exec=helium" "Exec=$out/bin/helium"

    runHook postInstall
  '';

  meta = {
    description = "Private, fast, and honest web browser (Chromium-based)";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "helium";
  };
})
