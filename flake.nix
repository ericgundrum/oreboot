{
  description = "oreboot dev config";
  inputs = {
    nixpkgs.url = "git+file:///nix/nixpkgs?ref=github/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, rust-overlay, naersk, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        localSystem = "${system}";
        overlays = [ rust-overlay.overlay ];
      };
      riscv-pkgs = import nixpkgs {
        localSystem = "${system}";
        crossSystem = {
          config = "riscv64-unknown-linux-gnu";
          abi = "lp64";
        };
      };
      rust_build =
        pkgs.rust-bin.fromRustupToolchainFile "${self}/rust-toolchain.toml";
      naersk_lib = naersk.lib."${system}".override {
        rustc = rust_build;
        cargo = rust_build;
      };
      sample_package = naersk_lib.buildPackage {
        pname = "oreboot";
        root = ./.;
      };
      sample_usage = pkgs.writeScript "run_sample" ''
        #!/usr/bin/env bash
        #${pkgs.qemu}/bin/qemu-system-riscv64 -kernel ${sample_package}/riscv64imac-unknown-none-elf/release/nix_example_kernel -machine sifive_u
        echo "--- BROKEN ---"
      '';
      cargo_config = throw "attribute `cargo_config` is undefined";
    in {
      devShell.x86_64-linux = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.qemu
          pkgs.dtc
          rust_build
          riscv-pkgs.buildPackages.gcc
          riscv-pkgs.buildPackages.gdb
        ];
      };
      apps.x86_64-linux.oreboot = {
        type = "app";
        program = "${sample_usage}";
      };
      defaultApp.x86_64-linux = self.apps.x86_64-linux.oreboot;
    };
}
