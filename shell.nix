{}: let

    rust-overlay = (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"));

    pkgs = (import <nixpkgs> {
        overlays = [ rust-overlay ];
    });

in let

    deps = with pkgs; [
        (pkgs.rust-bin.stable.latest.rust.override {
            extensions = ["rust-src"];
        })

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

    # rpath for output binaries
    rpath = pkgs.lib.makeLibraryPath deps;

    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

in pkgs.mkShell {
    inherit rpath;
    buildInputs = deps;
}