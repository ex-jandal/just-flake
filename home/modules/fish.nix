{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # - single source of truth for the plugin list; fed to ~/.config/fish/fish_plugins.
  fishPluginsFile = builtins.toFile "fish_plugins" (builtins.readFile ../../assets/fish/fish_plugins);
in
{
  imports = [
    inputs.nix-index-database.homeModules.default
  ];
  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;

  # - zoxide/fzf/eza/onefetch/lazygit live in home/packages.nix, not here.

  # - env vars in `home.sessionVariables` so they apply to fish and other shells
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
    MANPAGER = "nvim -c +Man!";
    # - dev environments resolved from the flake's nixpkgs
    JAVA_HOME = "${pkgs.jdk.home}";
    ANDROID_HOME = "$HOME/Android/Sdk";
    ANDROID_EMULATOR_HOME = "$HOME/.android";
    ANDROID_AVD_HOME = "$ANDROID_EMULATOR_HOME/avd";
    ANDROID_EMU_OPTIONS = "-gpu host -no-snapshot -accel on -qemu -enable-kvm";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    fish_lsp_server_path = "${pkgs.fish-lsp}/bin/fish-lsp";
    # - Java AWT/Swing GUI apps (Ghidra, etc.) render a blank window under niri
    #   + xwayland-satellite (non-reparenting WM) unless AWT is told not to
    #   assume reparenting. See xwayland-satellite README + niri wiki.
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # - reach the overlay libs inside lutris's FHS: its profile prepends to the
    #   inherited PATH and bwrap does not clear the environment. Drop
    #   WINEDEBUG to see wine's stderr when a game misbehaves.
    MANGOHUD = "1";
    ENABLE_VKBASALT = "1";
    WINEDEBUG = "-all";
  };

  # - `nipe` is user-authored and ships with no plugin, so it stays managed
  #   here. The git-helper functions (gbuild/_gc/gci/...) are deliberately NOT
  #   managed: they are byte-identical to gazorby/fish-git-emojis, and fisher
  #   refuses to install a plugin whose files already exist under
  #   ~/.config/fish/functions. They still resolve via $fish_function_path.
  home.file.".config/fish/functions/nipe.fish".source = ../../assets/fish/functions/nipe.fish;

  programs.fish = {
    enable = true;
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
              fortune -s # | lolcat -g 777777:cccccc
      end

      ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
    '';

    # - mirrors assets/fish/fish_plugins, pinned. `name` must not contain "/":
    #   HM interpolates it into conf.d/plugin-${name}.fish, and fish autoloads
    #   conf.d/*.fish at top level only, so "owner/repo" would never be read.
    plugins = [
      {
        name = "fisher";
        # - fetchgit rather than fetchFromGitHub: the latter pulls a tarball from
        #   codeload.github.com, which is unreachable from this network.
        src = pkgs.fetchgit {
          url = "https://github.com/jorgebucaran/fisher";
          rev = "791da644d33d392216f6b1a9b5fc1e470db6d7f2";
          sha256 = "185nzkbnsgrmq9pj1llmw6a6w29sbb656r4imkbv2qksdvr9sp2k";
        };
      }
      {
        name = "pisces";
        src = pkgs.fetchFromGitHub {
          owner = "laughedelic";
          repo = "pisces";
          rev = "e45e0869855d089ba1e628b6248434b2dfa709c4";
          sha256 = "073wb83qcn0hfkywjcly64k6pf0d7z5nxxwls5sa80jdwchvd2rs";
        };
      }
      {
        name = "fzf_fish";
        src = pkgs.fetchFromGitHub {
          owner = "patrickf1";
          repo = "fzf.fish";
          rev = "6a6136998879dcc1f29a405dfdd6b92c5f229c39";
          sha256 = "0fbir8vmkkjsdcsvpfrn3m2agz25q9bc6g9fr0ly5h66qnfi8pxa";
        };
      }
      {
        name = "fish_git_emojis";
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
      # lazyvim = "NVIM_APPNAME=lazyvim ${pkgs.neovim}/bin/nvim";
      onefetch = "onefetch --nerd-fonts";
      ssh-kali = "ssh kali@192.168.122.60";
      ssh-parrot = "ssh parrot@192.168.122.99";
      current_time = "date +\"Today is %A, %B %d, %Y and the time is %I:%M:%S %p\"";
      surreal-start = "surreal start --log debug --user root --pass root file://$HOME/project/surrealdb-database/main";
      surreal-sql = "surreal sql --user root --pass root --namespace test --database test --pretty";
      run-hotspot = "sudo ~/linuxrouter --ap wlan0 'abu_jandal - archlinux' -g 137 --freq-band 2.4 -6 -p";
      run-hotspot5 = "sudo ~/linuxrouter --ap wlan0 'abu_jandal - archlinux' -g 137 --freq-band 5 -6 -p";
      tbrowser = "nix develop ~/just-flake#term-browser -c terminal-browser";
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
      convert_social = {
        description = "Compress and convert video for social media compatibility";
        body = ''
          if test (count $argv) -lt 2
              echo "Error: Missing arguments."
              echo "Usage: convert_social <input_file> <output_file> [crf]"
              return 1
          end

          set -l input $argv[1]
          set -l output $argv[2]
          set -l crf 28
          if test (count $argv) -ge 3
              set crf $argv[3]
          end

          if not test -f "$input"
              echo "Error: Input file '$input' does not exist."
              return 1
          end

          ${pkgs.ffmpeg}/bin/ffmpeg -i "$input" \
              -c:v libx264 \
              -crf $crf \
              -preset slow \
              -c:a aac \
              -b:a 96k \
              "$output"
        '';
      };
      sp = {
        description = "Bridge Obsidian daily notes and Super Productivity";
        body = ''
          # - The bridge lives in the notes repo, not the nix store: it resolves
          #   the vault from its own path and `sp log` writes back into it.
          set -l bridge $HOME/project/start-with-cyber/para/tools/sp-bridge.py

          if not test -f $bridge
              echo "sp: bridge not found at $bridge" >&2
              return 1
          end

          # - stdlib only on purpose, so there is no venv to keep in sync.
          ${pkgs.python3}/bin/python3 $bridge $argv
        '';
      };
    };
  };

  # - Seed ~/.config/fish/fish_plugins once; it is the list bare `fisher
  #   update` reconciles against, so one command pulls in all four plugins.
  #   Deliberately *not* a home.file: fisher rewrites the file after every
  #   install/update/remove, which would fail on a read-only store symlink.
  #   Once written it is an ordinary user file; cleanOldGen only considers paths
  #   recorded in a generation, so it survives rebuilds.
  home.activation.fisherPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    fish_plugins="$HOME/.config/fish/fish_plugins"
    mkdir -p "$(dirname "$fish_plugins")"
    if [ ! -e "$fish_plugins" ]; then
      cat ${fishPluginsFile} >"$fish_plugins"
    fi
  '';
}
