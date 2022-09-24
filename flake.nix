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

		# utilities for reading Cargo.toml
		naersk = {
			url = "github:nmattia/naersk";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		smithay = {
			url = "path:./smithay";
		};
	};

	outputs = { self, nixpkgs, utils, rust-overlay, crate2nix, naersk, smithay, ... }:
	let
		cargoToml = (builtins.fromTOML (builtins.readFile ./Cargo.toml));
		name = "${cargoToml.package.name}";
		version = "${cargoToml.package.version}";
	in
	utils.lib.eachDefaultSystem(system:
		let
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
			inherit (import "${crate2nix}/tools.nix" { inherit pkgs; })
			generatedCargoNix;

			# Create the cargo2nix project
			project = pkgs.callPackage(generatedCargoNix {
				inherit name;
				src = ./.;
			})

			{
				defaultCrateOverrides = pkgs.defaultCrateOverrides // {
				# The app crate itself is overriden here. Typically we
				# configure non-Rust dependencies (see below) here.
				${name} = oldAttrs: {
					inherit buildInputs nativeBuildInputs;
				} // buildEnvVars;
				};
			};

			# Configuration for the non-Rust dependencies
			buildInputs = with pkgs; [ openssl.dev ];
			nativeBuildInputs = with pkgs; [ rustc cargo pkgconfig nixpkgs-fmt ];
			buildEnvVars = {
				PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
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
				inherit buildInputs nativeBuildInputs;
				RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
			} // buildEnvVars;
		}
	);
}