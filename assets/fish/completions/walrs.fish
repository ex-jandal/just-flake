# walrs completion for fish shell

# Clear existing completions
complete -c walrs -e

# Basic flags
complete -c walrs -s i -l image -d "path to image or directory" -r -F
complete -c walrs -s r -l reload -d "reload without changing the wallpaper"
complete -c walrs -s R -l reload-no -d "will be removed in the next update; use -w instead"  
complete -c walrs -s t -l theme -d "use external theme file from .config/walrs/colorschemes" -r -F
complete -c walrs -s g -l generate -d "generate & save theme to .config/walrs/colorschemes" -x
complete -c walrs -s s -l saturation -d "set saturation value (-128 to 127)" -x
complete -c walrs -s b -l brightness -d "set brightness value (-128 to 127)" -x
complete -c walrs -s S -l scripts -d "skip running scripts in ~/.config/walrs/scripts/"
complete -c walrs -s W -l walless -d "skip changing the wallpaper"
complete -c walrs -s q -l quiet -d "set quit mode (no output)"
complete -c walrs -s v -l version -d "show version"
complete -c walrs -l help -d "display help"
complete -c walrs -a help -d "display help"

# Saturation and brightness numeric completion
for i in (seq -128 127)
    complete -c walrs -s s -l saturation -x -a "$i"
    complete -c walrs -s b -l brightness -x -a "$i"
end
