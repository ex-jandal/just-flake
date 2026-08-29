# Hardware configuration — PLACEHOLDER.
#
# Generated automatically by `nixos-generate-config --root /` on the real
# machine. Replace this file with the generated `hardware-configuration.nix`
# (from the Arch box: ext4 `/` UUID=3492e124-..., vfat `/boot` UUID=C44E-BC6E,
# 4G /swapfile, AMD Barcelo iGPU via amdgpu/vulkan-radeon).
#
# The placeholder `fileSystems."/"` below is only so `nix flake check`
# evaluates during migration planning. Overwriting this file with the real
# generated config supersedes it — do NOT declare `fileSystems` again in
# default.nix, or you'll get a duplicate-definition error.

{
  imports = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "ext4";
  };
}
