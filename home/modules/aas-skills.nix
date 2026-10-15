{ inputs, lib, ... }:
let
  # - Agentic Awesome Skills ships ~2.6k skill folders under `skills/`.
  # - Linked straight from the flake input with home.file/xdg.configFile rather
  #   than programs.{opencode,codex}.skills: the module's skills option wraps
  #   every value in its own derivation (normalizeSkill / mkSkillDir), i.e. one
  #   build per skill per host. Plain `source` symlinks cost zero builds and
  #   coexist with the unmanaged skills already in those directories.
  # - A store-path string cannot be turned into a Nix path literal, so the
  #   modules' single-derivation directory branch is unreachable from a flake
  #   input anyway; this is the only form that stays cheap.
  skillsRoot = "${inputs.agentic-awesome-skills}/skills";
  skillDirs = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists "${skillsRoot}/${name}/SKILL.md"
  ) (builtins.readDir skillsRoot);
  mkLinks =
    base:
    lib.mapAttrs' (
      name: _: lib.nameValuePair "${base}/${name}" { source = "${skillsRoot}/${name}"; }
    ) skillDirs;
in
{
  # - opencode reads $XDG_CONFIG_HOME/opencode/skills/<name>/SKILL.md
  xdg.configFile = mkLinks "opencode/skills";

  # - CODEX_HOME defaults to ~/.codex (home.preferXdgDirectories is not set),
  #   and codex reads <skills-dir>/<name>/SKILL.md.
  home.file = mkLinks ".codex/skills";
}
