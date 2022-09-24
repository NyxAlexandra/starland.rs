#see: https://hoverbear.org/blog/a-flake-for-your-crate/
{
	description = "";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
		nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
		
		# utilities for toml
		naersk = {
			url = "github:nmattia/naersk";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, nixpkgs-wayland, naersk }@inputs:
	let
		system = "x86_64-linux"; #TODO: replace with an array of systems
		packageName = "${cargoToml.package.name}";
		version = "${cargoToml.package.version}";
		pkgs = import nixpkgs { inherit system; };

		buildInputs = with pkgs; [];

		nativeBuildInputs = with pkgs; [
			pkg-config

			rustup cargo

			wayland
			wayland-protocols
			egl-wayland
			udev
			dbus
			libxkbcommon
			libinput
		];

		cargoToml = (builtins.fromTOML (builtins.readFile ./Cargo.toml));
	in {
		packages."${system}".default = pkgs.stdenv.mkDerivation {
			pname = "${packageName}";
			inherit version;
			src = self;

			inherit buildInputs nativeBuildInputs;

			buildPhase = ''
				cargo build --release
			'';

			installPhase = ''
				runHook preInstall

				mkdir -p $out/bin
				cp target/release/starland $out/bin

				runHook postInstall
			'';
		};

		devShells.default = pkgs.mkShell {
			inherit buildInputs nativeBuildInputs;
			packages = [] ++ buildInputs nativeBuildInputs;
		};

		devShell = self.devShells.default;
	};
}