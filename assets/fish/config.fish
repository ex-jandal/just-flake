# This file is sourced on startup of each interactive fish shell.
function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

# Only run the following if the shell is interactive
if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

end

# Starship prompt
starship init fish | source

# Terminal sequences for quickshell and caelestia
# if not set -q TMUX
#     # cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
#     # cat .local/state/caelestia/sequences.txt
#     if test -s ~/.config/fish/sequences.txt
#         cat ~/.config/fish/sequences.txt
#     end
# end

# Aliases
alias pamcan pacman
alias ls 'eza --icons always'
alias clear "printf '\033[2J\033[3J\033[1;1H'"
# alias q 'qs -c ii'

# Load additional configurations and plugins
zoxide init fish | source
fzf --fish | source
onefetch --generate fish | source
go-pray completion fish | source
uv generate-shell-completion fish | source
mdbook completions fish | source
niri completions fish | source
laravel completion | source
cargo tauri completions --shell fish 2> /dev/null | source
golings completion fish | source
dx completions fish | source

# Enable vi keybindings
fish_vi_key_bindings

# Cursor style settings
# set fish_cursor_default block

# show underscore when in replace ('r')
set fish_cursor_replace_one underscore
set fish_cursor_replace underscore

# Fisher!
# Install Fisher if not already installed
if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end

fish_add_path $HOME/.config/composer/vendor/bin

# Java environment
set -x JAVA_HOME /usr/lib/jvm/java-26-openjdk
set -x PATH $JAVA_HOME/bin $PATH

# Go environment
fish_add_path --universal ~/go/bin
fish_add_path ~/.nimble/bin

# ~/.config/fish/conf.d/caelestia.fish
# if not status is-interactive; and not set -q TMUX
#     test -s ~/.local/state/caelestia/sequences.txt; and cat ~/.local/state/caelestia/sequences.txt
# end

# Aliases and environment variables

# pagers with nvim and bat
set -x MANPAGER "nvim -c +Man!"
set -x PAGER bat
set -x USER 'abu_jandal'
set -x MAIL 'sultan.m.alsalahi@gmail.com'
# set -x SIGNAL_SERVICE "127.0.0.1:8080"
# set -x PHONE_NUMBER "+967782424366"
alias paru-pro="paru --keepsrc --sudoloop --ssh --interactive"
# alias nvim "nvim --cmd 'set lazyredraw' " # faster nvim startup
alias lazyvim "NVIM_APPNAME=lazyvim nvim"
# alias vim "nvim"
alias onefetch "onefetch --nerd-fonts"
alias ssh-kali "ssh kali@192.168.122.60"
alias ssh-parrot "ssh parrot@192.168.122.99"
alias current_time "date +\"Today is %A, %B %d, %Y and the time is %I:%M:%S %p\""
function nipe
    set -l tmp_pwd $PWD
    builtin cd /home/abu_jandal/repos/nipe
    sudo perl nipe.pl $argv
    builtin cd $tmp_pwd
end
# funcsave nipe

# surrealdb commands aliases made easy to use
alias surreal-start "surreal start --log debug --user root --pass root file:///home/abu_jandal/project/surrealdb-database/main"
alias surreal-sql "surreal sql --user root --pass root --namespace test --database test --pretty"

# Set default editor to nvim
set -x EDITOR nvim

# function fish_command_not_found
#     pkgfile $argv[1]
# end
# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end
# alias x="clear"

# Enable Fish LSP
set -gx fish_lsp_enabled_handlers
set -gx fish_lsp_server_path /usr/bin/fish-lsp
# set -gx JDTLS_JVM_ARGS "-javaagent:$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar"
# set -gx JAVA_HOME /usr/lib/jvm/java-26-openjdk
set -gx JAVA_HOME /opt/android-studio/jbr
set -gx ANDROID_HOME "$HOME/Android/Sdk"
set -gx NDK_HOME "$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"
set -gx ANDROID_EMULATOR_HOME "$HOME/.android"
set -gx ANDROID_AVD_HOME "$ANDROID_EMULATOR_HOME/avd"
set -gx ANDROID_EMU_OPTIONS "-gpu host -no-snapshot -accel on -qemu -enable-kvm"

# set -gx ANDROID_HOME="$HOME/Android/Sdk"
# export JAVA_HOME="/usr/lib/jvm/default" # Adjust path as necessary
# Create the Sdk directory and move unzipped tools there (e.g., mv cmdline-tools $ANDROID_HOME/cmdline-tools)
# set -gx PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# fish_add_path /opt/android-sdk/cmdline-tools/latest/bin
fish_add_path $ANDROID_HOME/platform-tools
# fish_add_path $ANDROID_HOME/build-tools/30.0.0
# fish_add_path $ANDROID_HOME/emulator
# fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
# fish_add_path $ANDROID_HOME/emulator
# fish_add_path $NDK_HOME

# Auto-start Hyprland on tty1
# if status is-login
#     if test -z "$DISPLAY"; and test (tty) = "/dev/tty1"
#         exec uwsm app -- Hyprland
#     end
# end

# Function to safely eject a device
function ejectdev
    if test (count $argv) -ne 1
        echo "Usage: ejectdev <device_name> (e.g. sdb)"
        return 1
    end

    set dev /dev/$argv[1]

    # unmount all partitions
    for part in (lsblk -ln -o NAME $dev | tail -n +2)
        echo "Unmounting /dev/$part"
        sudo umount /dev/$part
    end

    echo "Powering off $dev"
    sudo udisksctl power-off -b $dev
end

# Function to list packages with big upgrades
function big-upgrade-packages
    sudo pacman -Su | awk '{printf("Package: %s -> %s %s\n", $1, $6, $7)}' | sort -k4,4n -rh | tail -n +17
end

# Show fortune cookie only if not in tmux
if set -q TMUX && not set -q NVIM && status is-interactive
    pokego --random 5 --no-title
    # Show a random fortune cookie on terminal start
    echo &&
        fortune -s | lolcat -g 777777:cccccc
end

# pnpm
set -gx PNPM_HOME "/home/abu_jandal/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end


# Added by Antigravity CLI installer
set -gx PATH "/home/abu_jandal/.local/bin" $PATH
