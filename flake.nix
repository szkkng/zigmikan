{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs =
    {
      zig,
      nixpkgs,
      ...
    }:
    let
      allSystems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems =
        f: nixpkgs.lib.genAttrs allSystems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = forAllSystems (
        { pkgs }:
        {
          default =
            let
              pkgsX86 = import nixpkgs { system = "x86_64-linux"; };
            in
            pkgs.mkShell {
              packages = with pkgs; [
                zig.packages.${stdenv.hostPlatform.system}."0.16.0"
                zls
                qemu
              ];

              OVMF_CODE = "${pkgsX86.OVMF.firmware}";
              OVMF_VARS = "${pkgsX86.OVMF.variables}";
            };
        }
      );
    };
}
