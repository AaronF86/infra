{
  description = "Nix infrastructure for CM3588";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tangled.url = "git+https://tangled.org/tangled.org/core";
    colmena.url = "github:zhaofengli/colmena/release-0.4.x";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    friendlyelecCM3588 = {
      url = "github:YayaADev/nixos-friendlyelec-cm3588";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, colmena, tangled, friendlyelecCM3588, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      commonArgs = import ./common/ssh.nix;

      mkSystem = host:
        nixpkgs.lib.nixosSystem {
          system = host.system;
          specialArgs = {
            inherit commonArgs;
          };
          modules = host.modules;
        };

      # Helper function to create colmena host
      mkColmenaHost = host:
        {
          deployment = {
            targetHost = host.target;
            targetPort = 22;
            targetUser = "root";
            buildOnTarget = host.buildOnTarget;
          };
          nixpkgs.hostPlatform = host.system;
          imports = host.modules;
        };

      # Host configurations
      hosts = {
        cm3588 = {
          system = "aarch64-linux";
          buildOnTarget = true;
          modules = [
            disko.nixosModules.disko
            friendlyelecCM3588.nixosModules.cm3588
            tangled.nixosModules.knot
            ./hosts/cm3588/configuration.nix
            ./hosts/cm3588/services/knot.nix
            ./hosts/cm3588/services/nginx.nix
            ./hosts/cm3588/services/pds.nix
            ./hosts/cm3588/services/tunnel.nix
          ];
          target = "192.168.1.117";
        };

        gateway = {
          system = "x86_64-linux";
          buildOnTarget = false;
          modules = [
            disko.nixosModules.disko
            ./hosts/gateway/configuration.nix
            ./hosts/gateway/services/tunnel.nix
            ./hosts/gateway/services/nginx.nix
          ];
          target = "46.224.126.188";
        };
      };

      cm3588System = mkSystem hosts.cm3588;
      gatewaySystem = mkSystem hosts.gateway;
    in
    {
      packages = forAllSystems (system: {
        colmena = colmena.packages.${system}.colmena;
      });

      apps = forAllSystems (system: {
        colmena = {
          type = "app";
          program = "${colmena.packages.${system}.colmena}/bin/colmena";
        };
      });

      # nixos-anywhere and nixos-rebuild use these
      nixosConfigurations = {
        cm3588 = cm3588System;
        my-cm3588 = cm3588System;
        gateway = gatewaySystem;
      };

      # colmena uses this
      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
          specialArgs = {
            inherit commonArgs;
            tangled-pkgs = tangled.packages.aarch64-linux;
          };
        };

        defaults = { pkgs, ... }: {
          environment.systemPackages = [ pkgs.curl ];
        };

        cm3588 = mkColmenaHost hosts.cm3588;
        gateway = mkColmenaHost hosts.gateway;
      };
    };
}
