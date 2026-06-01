{
  description = "Infrastructure and deployment configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    colmena.url = "github:zhaofengli/colmena/release-0.4.x";

    tangled = {
      url = "git+https://tangled.org/tangled.org/core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    friendlyelecCM3588 = {
      url = "github:YayaADev/nixos-friendlyelec-cm3588";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    colmena,
    disko,
    sops-nix,
    tangled,
    friendlyelecCM3588,
    home-manager,
    zen-browser,
    ...
  }: let
    lib = nixpkgs.lib;

    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    forAllSystems = lib.genAttrs systems;

    commonArgs = import ./common/ssh.nix;

    mkHost = attrs:
      {
        buildOnTarget = true;
        targetUser = "aaron";
        targetPort = 2222;
      }
      // attrs;

    hosts = {
      desktop = mkHost {
        system = "x86_64-linux";

        deployment.targetHost = "192.168.1.216";

        modules = [
          disko.nixosModules.disko

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              extraSpecialArgs = {
                inherit inputs zen-browser;
              };

              users.aaron = import ./homeModules/aaron.nix;
            };
          }

          ./hosts/desktop/configuration.nix
        ];
      };
      framework13 = mkHost {
        system = "x86_64-linux";

        deployment.targetHost = "192.168.1.193";

        modules = [
          disko.nixosModules.disko

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              extraSpecialArgs = {
                inherit inputs zen-browser;
              };

              users.aaron = import ./homeModules/aaron.nix;
            };
          }

          ./hosts/framework13/configuration.nix
        ];
      };

      grimoire = mkHost {
        system = "aarch64-linux";

        deployment.targetHost = "192.168.1.116";

        modules = [
          friendlyelecCM3588.nixosModules.cm3588
          disko.nixosModules.disko
          sops-nix.nixosModules.sops

          ./hosts/grimoire/configuration.nix
          ./hosts/grimoire/services/samba.nix
          ./hosts/grimoire/services/postgres.nix
        ];
      };

      staff = mkHost {
        system = "x86_64-linux";

        deployment.targetHost = "192.168.1.243";

        modules = [
          sops-nix.nixosModules.sops

          tangled.nixosModules.knot
          tangled.nixosModules.spindle

          ./hosts/staff/configuration.nix

          ./hosts/staff/services/tunnel.nix
          ./hosts/staff/services/files.nix
          ./hosts/staff/services/pds.nix
          ./hosts/staff/services/knot.nix
          ./hosts/staff/services/spindle.nix
          ./hosts/staff/services/minecraft-forge.nix
          ./hosts/staff/services/stalwart.nix
          ./hosts/staff/services/github-runner.nix

          ./hosts/staff/services/openbao/openbao.nix
          ./hosts/staff/services/openbao/proxy.nix
        ];
      };

      gateway = mkHost {
        system = "x86_64-linux";

        deployment = {
          targetHost = "46.224.126.188";
        };

        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops

          ./hosts/gateway/configuration.nix

          ./hosts/gateway/services/tunnel.nix
          ./hosts/gateway/services/traefik.nix
          ./hosts/gateway/services/haproxy.nix
          ./hosts/gateway/services/nftables.nix
        ];
      };
    };

    mkSpecialArgs = system: {
      inherit
        self
        inputs
        commonArgs
        ;

      tangled-pkgs = tangled.packages.${system};
    };

    mkSystem = name: host:
      lib.nixosSystem {
        inherit (host) system;

        specialArgs = mkSpecialArgs host.system;

        modules = host.modules;
      };

    mkColmenaHost = name: host: {
      deployment = {
        targetHost = host.deployment.targetHost;
        targetPort = host.targetPort;
        targetUser = host.targetUser;
        buildOnTarget = host.buildOnTarget;
      };

      nixpkgs.hostPlatform = host.system;

      imports = host.modules;
    };
  in {
    formatter = forAllSystems (
      system: nixpkgs.legacyPackages.${system}.alejandra
    );

    packages = forAllSystems (
      system: {
        inherit (colmena.packages.${system}) colmena;
      }
    );

    apps = forAllSystems (
      system: {
        colmena = {
          type = "app";
          program = "${colmena.packages.${system}.colmena}/bin/colmena";
        };
      }
    );

    nixosConfigurations =
      lib.mapAttrs mkSystem hosts;

    colmenaHive = colmena.lib.makeHive (
      {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          specialArgs = mkSpecialArgs "x86_64-linux";
        };

        defaults = {pkgs, ...}: {
          environment.systemPackages = [
            pkgs.curl
          ];
        };
      }
      // lib.mapAttrs mkColmenaHost hosts
    );
  };
}
