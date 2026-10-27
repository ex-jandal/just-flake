{
  config,
  ...
}:
{
  sops = {
    # The user-level sops service reads this key. Copy it once with:
    #   install -d -m 700 ~/.config/sops/age
    #   install -m 600 .secrets/age.key ~/.config/sops/age/keys.txt
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = ../../.secrets/secrets.yaml;

    secrets.github_token = {
      key = "GITHUB_TOKEN";
    };

    templates."github.env".content = ''
      GITHUB_TOKEN=${config.sops.placeholder.github_token}
    '';
  };
}
