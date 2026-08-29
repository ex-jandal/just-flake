{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # fisher-managed plugins (fzf.fish, pisces, git-emojis) fetched at runtime;
    # provide the underlying tools + fish plugins dir.
    zoxide
    fzf
    eza
    onefetch
    lazygit
  ];

  # Env vars (in `home.sessionVariables` so they apply to fish and other shells).
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
    MANPAGER = "nvim -c +Man!";
    # --- Dev environments (Arch-specific paths — parametrize before NixOS) ---
    JAVA_HOME = "/usr/lib/jvm/java-26-openjdk";
    ANDROID_HOME = "$HOME/Android/Sdk";
    ANDROID_EMULATOR_HOME = "$HOME/.android";
    ANDROID_AVD_HOME = "$ANDROID_EMULATOR_HOME/avd";
    ANDROID_EMU_OPTIONS = "-gpu host -no-snapshot -accel on -qemu -enable-kvm";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    fish_lsp_server_path = "/usr/bin/fish-lsp";
  };

  # User-authored fish functions from the original config (git helpers, nipe).
  # Plugin-provided functions (fisher/fzf/pisces) are fetched at runtime and
  # deliberately NOT copied to avoid clobbering the runtime plugin installs.
  home.file.".config/fish/functions/gbuild.fish".source = ../../assets/fish/functions/gbuild.fish;
  home.file.".config/fish/functions/_gc.fish".source = ../../assets/fish/functions/_gc.fish;
  home.file.".config/fish/functions/gci.fish".source = ../../assets/fish/functions/gci.fish;
  home.file.".config/fish/functions/gdocs.fish".source = ../../assets/fish/functions/gdocs.fish;
  home.file.".config/fish/functions/gfeat.fish".source = ../../assets/fish/functions/gfeat.fish;
  home.file.".config/fish/functions/gfix.fish".source = ../../assets/fish/functions/gfix.fish;
  home.file.".config/fish/functions/gperf.fish".source = ../../assets/fish/functions/gperf.fish;
  home.file.".config/fish/functions/gref.fish".source = ../../assets/fish/functions/gref.fish;
  home.file.".config/fish/functions/gstyle.fish".source = ../../assets/fish/functions/gstyle.fish;
  home.file.".config/fish/functions/gtest.fish".source = ../../assets/fish/functions/gtest.fish;
  home.file.".config/fish/functions/nipe.fish".source = ../../assets/fish/functions/nipe.fish;

  programs.fish = {
    enable = true;
    # vi keybindings
    interactiveShellInit = ''
      fish_vi_key_bindings
      starship init fish | source
      zoxide init fish | source
      fzf --fish | source
      if command -v go-pray >/dev/null
        go-pray completion fish | source
      end
    '';

    shellAliases = {
      ls = "eza --icons always";
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
      lazyvim = "NVIM_APPNAME=lazyvim nvim";
      onefetch = "onefetch --nerd-fonts";
      ssh-kali = "ssh kali@192.168.122.60";
      ssh-parrot = "ssh parrot@192.168.122.99";
      current_time = "date +\"Today is %A, %B %d, %Y and the time is %I:%M:%S %p\"";
      surreal-start = "surreal start --log debug --user root --pass root file://$HOME/project/surrealdb-database/main";
      surreal-sql = "surreal sql --user root --pass root --namespace test --database test --pretty";
    };

    shellInit = ''
      # PATH additions matching the original config.fish
      fish_add_path --path $HOME/go/bin
      fish_add_path --path $HOME/.nimble/bin
      fish_add_path --path $HOME/.config/composer/vendor/bin
      fish_add_path --path $HOME/.cargo/bin
      fish_add_path --path $ANDROID_HOME/platform-tools 2>/dev/null || true
    '';

    functions = {
      ejectdev = ''
        if test (count $argv) -ne 1
            echo "Usage: ejectdev <device_name> (e.g. sdb)"
            return 1
        end
        set dev /dev/$argv[1]
        for part in (lsblk -ln -o NAME $dev | tail -n +2)
            echo "Unmounting /dev/$part"
            sudo umount /dev/$part
        end
        echo "Powering off $dev"
        sudo udisksctl power-off -b $dev
      '';
      big-upgrade-packages = ''
        sudo pacman -Su | awk '{printf("Package: %s -> %s %s\n", $1, $6, $7)}' | sort -k4,4n -rh | tail -n +17
      '';
    };
  };
}
