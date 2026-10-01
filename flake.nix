{
  description = "just-flake: NixOS + Home-Manager config (Niri + Noctalia)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      # - do NOT follow nixpkgs here — it would break the binary cache.
      url = "github:noctalia-dev/noctalia/cachix";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    xmcl = {
      url = "github:x45iq/xmcl-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rusbmux = {
      url = "github:abdullah-albanna/rusbmux";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # - Doom Emacs, prebuilt from nixpkgs/emacs-overlay instead of straight.el.
    #   Do NOT follow nixpkgs: Unstraightened pins its own nixpkgs for the
    #   elisp package set, and following ours breaks that pinning (its binary
    #   cache is built against its own nixpkgs anyway).
    doom-emacs.url = "github:marienz/nix-doom-emacs-unstraightened";
  };

  # - Noctalia binary cache lives in hosts/nixos/default.nix (nix.settings).
  #   A flake-level nixConfig.extra-trusted-public-keys would be ignored for
  #   untrusted users ("restricted setting") and just spam a warning.

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      noctalia,
      rusbmux,
      helium-flake,
      ...
    }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      homeConfigurations = {
        nixos = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            system = pkgs.stdenv.hostPlatform.system;
          };
          modules = [
            ./home/default.nix
            ({ ... }: {
              nixpkgs.config.allowUnfreePredicate = _: true;
              nixpkgs.config.joypixels.acceptLicense = true;
            })
          ];
        };
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        # - system set via `nixpkgs.hostPlatform` in hosts/nixos/default.nix.
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            # - home/default.nix needs the same inputs/system it gets via
            #   extraSpecialArgs in the standalone home-manager flake above.
            home-manager.extraSpecialArgs = {
              inherit inputs;
              system = pkgs.stdenv.hostPlatform.system;
            };
            home-manager.users.abu_jandal = import ./home/default.nix;
          }
        ];
      };

      formatter.${pkgs.stdenv.hostPlatform.system} =
        nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.nixfmt-rfc-style;

      devShells.${pkgs.stdenv.hostPlatform.system} = {
        cc = import ./shells/cc.nix { inherit pkgs; };
        py = import ./shells/python.nix { inherit pkgs; };
        term-browser = import ./shells/term-browser.nix { inherit pkgs; };
        tex = import ./shells/latex.nix { inherit pkgs; };
      };
    };
}
