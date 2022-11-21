{ #see: https://srid.ca/rust-nix
	description = "";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

		utils.url = "github:numtide/flake-utils";

		rust-overlay.url = "github:oxalica/rust-overlay";

		crate2nix = {
			url = "github:kolloch/crate2nix";
			flake = false;
		};

		flake-compat = {
			url = "github:edolstra/flake-compat";
			flake = false;
		};

		# smithay = {
		# 	url = "./smithay";
		# };
	};

	outputs = { self, nixpkgs, utils, rust-overlay, crate2nix, ... }:
	utils.lib.eachDefaultSystem(system:
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

	in let

			deps = with pkgs; [
				openssl.dev pkgconfig pkg-config

				rustc cargo pkgconfig nixpkgs-fmt pkg-config

				wayland
				wayland-protocols
				egl-wayland glew-egl gegl libglvnd freeglut
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
				libudev-zero libudev0-shim
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
			project = pkgs.callPackage(generatedCargoNix {
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

		in rec {
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