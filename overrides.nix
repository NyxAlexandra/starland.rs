{ rustLib, lib, pkgs, buildPackages }:
let
    inherit (rustLib) makeOverride nullOverride;
in {
    smithay = makeoverride {
        name = "smithay";
        overrideAttrs = drv: {
            src = "./smithay";
        };
    };
}
