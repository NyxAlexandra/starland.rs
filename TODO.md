## Main

- `starland`:
    - [x] Rename "anvil" to "starland"
    - [ ] Listen for messages
    - [ ] `clap`
    - [ ] Provide lots of information about window states
    - [ ] Border
    - [ ] Configuration
- `starctl`:
    - [ ] Send messages
    - [ ] `clap`
- [ ] Build and run on NixOS
    - [x] `nix develop`:
        - [x] Build
            - [x] Build dependencies
        - [x] Run
            - [x] Runtime dependencies
            - `libEGL`:
                - Seems to be a part of Mesa
            - Output of `readelf -d` (edited for conciseness):
                ```
                0x000000000000001d (RUNPATH)            Library runpath: [
                    /home/alex/Projects/starland.rs/outputs/out/lib64
                    /home/alex/Projects/starland.rs/outputs/out/lib
                    /nix/store/hhwkvh589y34p6znr2rcv28zw9afjccj-systemd-251.4/lib
                    /nix/store/nqdh1p4k0j157l6r9c6fanhsblpbhazw-mesa-22.1.7/lib
                    /nix/store/nqhhav800n5l1hi288inif77hs91k4yk-dbus-1.14.0-lib/lib
                    /nix/store/1fj50g70wkhcinc22a90icz23l231my4-wayland-1.21.0/lib
                    /nix/store/zrh2fzxx3cany19z0ikr9dl0rd6a935r-libxkbcommon-1.4.1/lib
                    /nix/store/ziqch0xd2ayp83jz9i2459agfkychpjc-libinput-1.21.0/lib
                    /nix/store/xhw7nff5jvgjds9xq00g1b78ldlil2r7-eudev-3.2.11/lib
                    /nix/store/bxn9rxki64l4xfm1kzxa16syz3rx2rrk-libudev-zero-1.0.1/lib
                    /nix/store/k21yr6kqq0bfdaq3myj4b30s8n99zy7j-systemd-minimal-251.4/lib
                    /nix/store/bzd91shky9j9d43girrrj6vmqlw7x9m8-glibc-2.35-163/lib
                    /nix/store/4v2bk6almk03mfnz4122dfz8vcxynvs3-gcc-11.3.0-lib/lib
                ]
                ```
            - Output of `patchelf --print-rpath` for the NixOS debug build (edited):
                ```
                /home/alex/Projects/starland.rs/outputs/out/lib64
                /home/alex/Projects/starland.rs/outputs/out/lib
                /nix/store/hhwkvh589y34p6znr2rcv28zw9afjccj-systemd-251.4/lib
                /nix/store/nqdh1p4k0j157l6r9c6fanhsblpbhazw-mesa-22.1.7/lib
                /nix/store/nqhhav800n5l1hi288inif77hs91k4yk-dbus-1.14.0-lib/lib
                /nix/store/1fj50g70wkhcinc22a90icz23l231my4-wayland-1.21.0/lib
                /nix/store/zrh2fzxx3cany19z0ikr9dl0rd6a935r-libxkbcommon-1.4.1/lib
                /nix/store/ziqch0xd2ayp83jz9i2459agfkychpjc-libinput-1.21.0/lib
                /nix/store/xhw7nff5jvgjds9xq00g1b78ldlil2r7-eudev-3.2.11/lib
                /nix/store/bxn9rxki64l4xfm1kzxa16syz3rx2rrk-libudev-zero-1.0.1/lib
                /nix/store/k21yr6kqq0bfdaq3myj4b30s8n99zy7j-systemd-minimal-251.4/lib
                /nix/store/bzd91shky9j9d43girrrj6vmqlw7x9m8-glibc-2.35-163/lib
                /nix/store/4v2bk6almk03mfnz4122dfz8vcxynvs3-gcc-11.3.0-lib/lib
                ```
            - Ouput of `patchelf --print-rpath` for the Arch debug build:
                ```

                ```
            - Turns out the solution was create a variable `rpath = lib.makeLibraryPath deps`, then running `patchelf --set-rpath $rpath`
    - [ ] `nix build`:
        - [ ] Build
            - "Can't resolve 'smithay' as depency" (crate2nix issue)
        - [ ] Run
    - [ ] Clean up dependencies to remove unneeded ones
- [ ] Contribute to Smithay
    - [ ] Dependencies list
    - [ ] 'flake.nix'

### Notes

- A good tool for debugging Nix-related headaches is Distrobox
- `ldd`: Displays library links
- `patchelf`: Changes binary dependencies