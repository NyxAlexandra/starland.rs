# stolen (mostly) from
# <https://github.com/pop-os/cosmic-comp/blob/master_jammy/flake.nix>.

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, crane, fenix, ... } @ inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        # helper to read the `Cargo.toml` file.
        cargoToml = (builtins.fromTOML (builtins.readFile ./Cargo.toml));

        name = "${cargoToml.package.name}";
        version = "${cargoToml.package.version}";

        # pkgs = nixpkgs.legacyPackages.${system};
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLib = crane.lib.${system};
        # craneLib = crane.lib.${system}.overrideToolchain fenix.packages.${system}.stable.toolchain;

        thisPackage = {
          src = nix-filter.lib.filter {
            root = ./.;
            include = [
              "src"
              "resources"
              "smithay"

              ./Cargo.toml
              ./Cargo.lock
              ./smithay
            ];
          };
          nativeBuildInputs = with pkgs; [ pkg-config autoPatchelfHook ];
          buildInputs = with pkgs; [
            wayland
            systemd # For libudev
            seatd # For libseat
            libxkbcommon
            libinput
            mesa # For libgbm

            dbus

            openssl.dev
            rustc
            cargo
            nixpkgs-fmt

            wayland-protocols
            egl-wayland
            glew-egl
            gegl
            libglvnd
            freeglut
            wayland-scanner
            wayland-utils
            xwayland
            waylandpp

            udev
            libxkbcommon
            libinput
            xorg.libX11
            systemd
            mesa # required for the 'gbm' crate
            elogind
            eudev
            libdrm
            libudev-zero
            libudev0-shim
            systemdMinimal
            gcc
            glibc
          ];
          runtimeDependencies = with pkgs; [ libglvnd ]; # For libEGL
        };

        # Saved build results of dependencies.
        cargoArtifacts = craneLib.buildDepsOnly thisPackage;

        drv = craneLib.buildPackage (thisPackage // {
          inherit cargoArtifacts;
        });

      in
      rec
      {
        packages.default = drv;

        apps.default = flake-utils.lib.mkApp {
          drv = drv;
        };

        checks = { inherit drv; };

        devShells.default = pkgs.mkShell rec {
          # inputsFrom = builtins.attrValues self.checks.${system};
          nativeBuildInputs = thisPackage.nativeBuildInputs;
          buildInputs = thisPackage.buildInputs;
          runtimeDependencies = thisPackage.runtimeDependencies;
          # Used when manually building via something like `cargo build`
          # in a devshell. The binary's rpath is not set automatically,
          # so you need to patch it with `patchelf`.
          rpath = pkgs.lib.makeLibraryPath (thisPackage.buildInputs ++ thisPackage.runtimeDependencies);
          LD_LIBRARY_PATH = pkgs.lib.strings.makeLibraryPath
            (builtins.concatMap (d: d.runtimeDependencies) (builtins.attrValues self.checks.${system}));
        };
      });
}

/*
  {
  #see: https://srid.ca/rust-nix
  description = "";

  inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  utils.url = "github:numtide/flake-utils";

  rust-overlay.url = "github:oxalica/rust-overlay";

  crate2nix = {
  url = "github:kolloch/crate2nix";
  flake = false;
  };
  };

  outputs = { self, nixpkgs, utils, rust-overlay, crate2nix, ... }:
  utils.lib.eachDefaultSystem (system:
  let
  cargoToml = (builtins.fromTOML (builtins.readFile ./Cargo.toml));
  name = "${cargoToml.package.name}";
  version = "${cargoToml.package.version}";

  # environment variables
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

  pkgs = import nixpkgs {
  inherit system;
  overlays = [
  rust-overlay.overlay
  (self: super: {
  # Because rust-overlay bundles multiple rust packages into one
  # derivation, specify that mega-bundle here, so that crate2nix
  # will use them automatically.
  rustc = self.rust-bin.stable.latest.default;
  cargo = self.rust-bin.stable.latest.default;
  })
  ];
  };

  in
  let

  deps = with pkgs; [
  openssl.dev
  pkgconfig
  pkg-config

  rustc
  cargo
  pkgconfig
  nixpkgs-fmt
  pkg-config

  wayland
  wayland-protocols
  egl-wayland
  glew-egl
  gegl
  libglvnd
  freeglut
  wayland-scanner
  wayland-utils
  xwayland
  waylandpp

  udev
  dbus
  libxkbcommon
  libinput
  xorg.libX11
  systemd
  mesa # required for the 'gbm' crate
  elogind
  eudev
  libdrm
  libudev-zero
  libudev0-shim
  systemdMinimal
  gcc
  glibc
  ];

  rpath = pkgs.lib.makeLibraryPath deps;

  # Needed by rust-analyzer to function
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  nativeBuildInputs = deps;
  buildInputs = deps;

  inherit (import "${crate2nix}/tools.nix" { inherit pkgs; }) generatedCargoNix;

  # Create the crate2nix project
  project = pkgs.callPackage
  (generatedCargoNix {
  inherit name;
  src = ./.;
  })

  {
  defaultCrateOverrides = pkgs.defaultCrateOverrides // {
  ${name} = oldAttrs: {
  inherit buildInputs nativeBuildInputs;
  };

  preBuild = ''
  git submodule update
  '';

  postFixup = ''
  patchelf --set-rpath ${rpath} $out/bin/${name}
  '';
  };
  };

  in
  rec {
  packages.${name} = project.rootCrate.build;

  # `nix build`
  defaultPackage = packages.${name};

  # `nix run`
  apps.${name} = utils.lib.mkApp {
  inherit name;
  drv = packages.${name};
  };

  defaultApp = apps.${name};

  # `nix develop`
  devShell = pkgs.mkShell {
  inherit buildInputs nativeBuildInputs rpath RUST_SRC_PATH;
  };
  }
  );
  }
*/

