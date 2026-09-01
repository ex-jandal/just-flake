{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # fisher plugins (see assets/fish/fish_plugins) are now declared below via
    # programs.fish.plugins (HM-generated fish_plugins + vendor symlinks); here
    # just provide the underlying tools the plugins need.
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
      set fish_greeting ""
      fish_vi_key_bindings
      starship init fish | source
      zoxide init fish | source
      # fzf.fish plugin owns the ctrl-cr/r/alt-c bindings; `fzf --fish` would
      # fight it, so its raw source is omitted here.
      if command -v go-pray >/dev/null
        go-pray completion fish | source
      end
      if set -q TMUX && not set -q NVIM && status is-interactive
          pokego --random 5 --no-title
          # Show a random fortune cookie on terminal start
          echo &&
              fortune -s | lolcat -g 777777:cccccc
      end
    '';

    # Mirrors the Arch fish_plugins list (assets/fish/fish_plugins): pisces
    # (brackets/parens auto-pairing), fzf.fish (fzf keybindings + previews),
    # fish-git-emojis (gitmoji in commit subject). Pinned declaratively.
    plugins = [
      {
        name = "laughedelic/pisces";
        src = pkgs.fetchFromGitHub {
          owner = "laughedelic";
          repo = "pisces";
          rev = "e45e0869855d089ba1e628b6248434b2dfa709c4";
          sha256 = "073wb83qcn0hfkywjcly64k6pf0d7z5nxxwls5sa80jdwchvd2rs";
        };
      }
      {
        name = "patrickf1/fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "patrickf1";
          repo = "fzf.fish";
          rev = "6a6136998879dcc1f29a405dfdd6b92c5f229c39";
          sha256 = "0fbir8vmkkjsdcsvpfrn3m2agz25q9bc6g9fr0ly5h66qnfi8pxa";
        };
      }
      {
        name = "gazorby/fish-git-emojis";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-git-emojis";
          rev = "a7fb5f3483618a8b72acfdc01394be04bcf50bf6";
          sha256 = "0mkdmdl4hifg3xvfxg267jrbqfa4rzjd2a1pzam56pdmgm5s7dw9";
        };
      }
    ];

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
