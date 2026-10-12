{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.abu_jandal.extraGroups = [
    "kvm"
    "adbusers"
  ];
  users.groups.kvm = { };
  users.groups.adbusers = { };
}
