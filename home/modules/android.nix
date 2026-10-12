{
  config,
  pkgs,
  lib,
  ...
}:

let
  sdk = "${config.home.homeDirectory}/Android/Sdk";

  # Run Google's emulator inside a conventional Linux runtime.
  androidEmulator = pkgs.writeShellScriptBin "android-emulator" ''
    set -eu

    SDK="$HOME/Android/Sdk"

    if [ ! -x "$SDK/emulator/emulator" ]; then
      echo "Android Emulator not found at $SDK/emulator/emulator" >&2
      exit 1
    fi

    export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-xcb}"

    exec ${pkgs.steam-run}/bin/steam-run \
      "$SDK/emulator/emulator" "$@"
  '';

  # Convenience wrapper for Google's SDK Manager.
  androidSdkManager = pkgs.writeShellScriptBin "sdkmanager" ''
    set -eu
    exec "$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager" "$@"
  '';

  androidAvdManager = pkgs.writeShellScriptBin "avdmanager" ''
    set -eu
    exec "$HOME/Android/Sdk/cmdline-tools/latest/bin/avdmanager" "$@"
  '';
in
{
  home.packages = with pkgs; [
    flutter
    # jdk17
    git
    androidEmulator
    androidSdkManager
    androidAvdManager
  ];

  home.sessionVariables = {
    ANDROID_HOME = sdk;
    ANDROID_SDK_ROOT = sdk;
  };

  home.sessionPath = [
    "${sdk}/platform-tools"
    "${sdk}/emulator"
    "${sdk}/cmdline-tools/latest/bin"
  ];

  # Commands usable from any project directory.
  home.shellAliases = {
    fl = "flutter";
    flr = "flutter run";
    flt = "flutter test";
    flb = "flutter build apk";
    adbdev = "adb devices -l";
    emu-list = "emulator -list-avds";
    emu-pixel = "android-emulator -avd Pixel_9_Pro_XL -gpu swiftshader";
  };
}
