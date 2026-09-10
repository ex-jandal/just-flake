{
  description = "just-flake: NixOS + Home-Manager config (Niri + Noctalia)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      # NOTE: do NOT follow nixpkgs here — it would break the binary cache.
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-flake =  {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xmcl = {
      url = "github:x45iq/xmcl-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rusbmux = {
      url = "github:ex-jandal/rusbmux/ex-jandal/nix-flake";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

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
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Home-manager flake — works on Arch now (test via `home-manager build`).
      homeConfigurations = {
        nixos = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs system;
          };
          modules = [
            ./home/default.nix
            # Standalone config builds its own pkgs, so unfree/license gates
            # must be set here. The NixOS path (useGlobalPkgs) inherits them
            # from hosts/nixos/default.nix instead — never set nixpkgs.* in
            # the shared home/default.nix.
            ({ lib, ... }: {
              nixpkgs.config.allowUnfreePredicate = _: true;
              nixpkgs.config.joypixels.acceptLicense = true;
            })
          ];
        };
      };

      # Phase 2 — NixOS system config.
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        # system is set via `nixpkgs.hostPlatform` in hosts/nixos/default.nix.
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            # home/default.nix needs the same inputs/system it gets via
            # extraSpecialArgs in the standalone home-manager flake above.
            home-manager.extraSpecialArgs = { inherit inputs system; };
            home-manager.users.abu_jandal = import ./home/default.nix;
          }
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

      devShells.${system} = {
        cc = pkgs.mkShell {
          packages = with pkgs; [
            # Compilers + build tools
            gcc gnumake cmake pkg-config

            # Clang ecosystem
            clang clang-tools

            # Debuggers + profilers
            gdb lldb valgrind strace

            # Linting
            cppcheck

            # Common C++ libraries (headers + pkg-config files)
            gtest catch2 spdlog fmt nlohmann_json
          ];

          shellHook = ''
            echo "C/C++ devShell active"
            echo "  gcc:   $(gcc --version | head -1)"
            echo "  clang: $(clang --version | head -1)"
            echo "  cmake: $(cmake --version | head -1)"
          '';
        };
      };
    };
}
