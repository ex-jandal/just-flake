# Cisco Packet Tracer 9.0.1 from the official Ubuntu .deb — newer than
# nixpkgs's cisco-packet-tracer_9 (9.0.0), so we build our own following the
# exact same recipe (requireFile -> unpack deb -> extract AppImage ->
# appimageTools.wrapType2).
#
# The deb must be registered in the Nix store once (requireFile flow, same as
# nixpkgs):
#
#   nix-store --add-fixed sha256 ~/Downloads/CiscoPacketTracer_901_Ubuntu_64bit.deb
#   # or: nix-prefetch-url file:///home/abu_jandal/Downloads/CiscoPacketTracer_901_Ubuntu_64bit.deb
#
# The deb ships a single AppImage at opt/pt/packettracer.AppImage. The wrapper
# adds libpng/libxkbfile and forces QT_QPA_PLATFORM=xcb (Wayland/niri launch
# fix); it then runs under XWayland themed via qt6ct.
{
  pkgs,
  lib,
}:

let
  appimage = pkgs.stdenvNoCC.mkDerivation {
    pname = "cisco-packet-tracer-appimage";
    version = "9.0.1";

    src = pkgs.requireFile {
      name = "CiscoPacketTracer_901_Ubuntu_64bit.deb";
      hash = "sha256-NoPdh+d5iFNyrpo1wabllNEvST5knnxpdAhynBRZR5s=";
      url = "https://www.netacad.com/resources/lab-downloads";
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = "true";

    installPhase = ''
      runHook preInstall

      dpkg-deb -x "$src" unpacked
      cp unpacked/opt/pt/packettracer.AppImage "$out"

      runHook postInstall
    '';
  };
in
pkgs.appimageTools.wrapType2 rec {
  pname = "cisco-packet-tracer";
  inherit (appimage) version;

  src = appimage;

  extraPkgs = _: [
    pkgs.libpng
    pkgs.libxkbfile
  ];

  extraBwrapArgs = [
    # fixes launch on wayland when the user sets QT_QPA_PLATFORM=wayland:
    # "Fatal: This application failed to start because no Qt platform plugin could be initialized."
    "--setenv QT_QPA_PLATFORM xcb"
  ];

  extraInstallCommands =
    let
      contents = pkgs.appimageTools.extract { inherit pname version src; };
    in
    ''
      mv $out/bin/${pname} $out/bin/packettracer

      install -Dm444 ${contents}/CiscoPacketTracer-[!P]*.desktop $out/share/applications/cisco-packet-tracer-9.desktop
      for d in ${contents}/CiscoPacketTracerPtsa-*.desktop; do
        [ -e "$d" ] || continue
        install -m 0644 "$d" $out/share/applications/cisco-packet-tracer-ptsa-9.desktop
      done

      for desktop in $out/share/applications/*.desktop; do
        substituteInPlace "$desktop" \
          --replace-fail "Exec=@EXEC_PATH@" "Exec=packettracer" \
          --replace-fail "Icon=app" "Icon=cisco-packet-tracer-9"
      done

      install -Dm444 ${contents}/usr/share/icons/hicolor/48x48/apps/app.png $out/share/icons/hicolor/48x48/apps/cisco-packet-tracer-9.png
      cp -r ${contents}/usr/share/icons/gnome/48x48/mimetypes $out/share/icons/hicolor/48x48/

      for desktop in $out/share/applications/*.desktop; do
        sed -i '/^\[Desktop Entry\]/a StartupWMClass=PacketTracer' "$desktop"
      done
    '';

  meta = {
    description = "Network simulation tool from Cisco";
    homepage = "https://www.netacad.com/courses/packet-tracer";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ gepbird ];
    mainProgram = "packettracer";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}