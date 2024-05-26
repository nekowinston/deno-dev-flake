{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fenix.url = "github:nix-community/fenix";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      devShells = forAllSystems (system: {
        default =
          let
            pkgs = nixpkgs.legacyPackages.${system};
            fenix = inputs.fenix.packages.${system}.latest;
          in
          pkgs.mkShell {
            env.RUST_SRC_PATH = "${fenix.rust-src}/lib/rustlib/src/rust/library";

            nativeBuildInputs = with pkgs; [
              # required by libz-ng-sys crate
              cmake
              # required by deno_kv crate
              protobuf
            ];

            buildInputs =
              with pkgs;
              [
                fenix.toolchain
                rust-analyzer
                cargo-watch
              ]
              ++ lib.optionals stdenv.isDarwin (
                [
                  libiconv
                  darwin.libobjc
                ]
                ++ (with darwin.apple_sdk_11_0.frameworks; [
                  Security
                  CoreServices
                  Metal
                  MetalPerformanceShaders
                  Foundation
                  QuartzCore
                ])
                ++ lib.optionals (stdenv.isAarch64) [ llvmPackages.lld ]
              );
          };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      nixConfig = {
        extra-substituters = [ "https://nix-community.cachix.org" ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
