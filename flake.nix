{
  description = "Nix infrastructure for CM3588";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tangled.url = "git+https://tangled.org/tangled.org/core";
    colmena.url = "github:zhaofengli/colmena/release-0.4.x";
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
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    sops-nix,
    colmena,
    tangled,
    friendlyelecCM3588,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
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
    mkColmenaHost = host: {
      deployment = {
        targetHost = host.target;
        targetPort = host.targetPort or 2222;
        targetUser = host.targetUser or "root";
        buildOnTarget = host.buildOnTarget;
      };
      nixpkgs.hostPlatform = host.system;
      imports = host.modules;
    };

    # Host configurations
    # NAS
    hosts = {
      grimoire = {
        system = "aarch64-linux";
        buildOnTarget = true;
        targetUser = "aaron";

        modules = [
          friendlyelecCM3588.nixosModules.cm3588
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/grimoire/configuration.nix
          ./hosts/grimoire/services/samba.nix
        ];
        target = "192.168.1.116";
      };

      # High power Compute Node.
      staff = {
        system = "x86_64-linux";
        buildOnTarget = true;
        targetUser = "aaron";

        modules = [
          sops-nix.nixosModules.sops
          tangled.nixosModules.knot
          tangled.nixosModules.spindle
          ./hosts/staff/configuration.nix
          ./hosts/staff/services/tunnel.nix
          ./hosts/staff/services/files.nix
          ./hosts/staff/services/pds.nix
          ./hosts/staff/services/knot.nix
          ./hosts/staff/services/opebao/openbao.nix
          ./hosts/staff/services/opebao/proxy.nix
          ./hosts/staff/services/spindle.nix
        ];
        target = "192.168.1.236";
      };

      # WAN-facing tunnel
      gateway = {
        system = "x86_64-linux";
        buildOnTarget = true;
        targetUser = "aaron";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/gateway/configuration.nix
          ./hosts/gateway/services/tunnel.nix
          ./hosts/gateway/services/ssh-forward.nix
          ./hosts/gateway/services/traefik.nix
        ];
        target = "46.224.126.188";
      };
    };

    grimoireSystem = mkSystem hosts.grimoire;
    staffSystem = mkSystem hosts.staff;
    gatewaySystem = mkSystem hosts.gateway;
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

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
      grimoire = grimoireSystem;
      staff = staffSystem;
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

      defaults = {pkgs, ...}: {
        environment.systemPackages = [pkgs.curl];
      };

      grimoire = mkColmenaHost hosts.grimoire;
      staff = mkColmenaHost hosts.staff;
      gateway = mkColmenaHost hosts.gateway;
    };
  };
}
