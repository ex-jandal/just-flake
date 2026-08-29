function nipe
    # Save the current directory, move to the repo, run nipe with all arguments, and return
    builtin cd /home/abu_jandal/repos/nipe; and sudo perl nipe.pl $argv; and builtin cd -
end
