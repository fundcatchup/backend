{
  description = "FundCatchup dev environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Pin Tilt to version 0.33.5 until an updated build of Nix's upstream
    # unstable pkgs addresses a build error.
    #
    # References: https://github.com/tilt-dev/tilt/pull/6214
    # References: https://github.com/NixOS/nixpkgs/issues/260411
    # See: https://lazamar.co.uk/nix-versions/?channel=nixos-unstable&package=tilt
    tilt-pin-pkgs.url = "https://github.com/NixOS/nixpkgs/archive/e1ee359d16a1886f0771cc433a00827da98d861c.tar.gz";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    tilt-pin-pkgs,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [
        (import rust-overlay)
      ];
      pkgs = import nixpkgs {inherit overlays system;};
      rustVersion = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      rust-toolchain = rustVersion.override {
        extensions = ["rust-analyzer" "rust-src"];
      };
      tilt-pin = import tilt-pin-pkgs {inherit system;};

      buck2NativeBuildInputs = with pkgs; [
        buck2
        python3
        ripgrep
        cacert
        clang
        lld
        rust-toolchain
      ];

      pythonEnv = pkgs.python3.withPackages (ps: [
        ps.aiohttp
        ps.gql
      ]);

      nativeBuildInputs = with pkgs;
        [
          envsubst
          nodejs
          tilt-pin.tilt
          typescript
          bats
          postgresql
          alejandra
          gnumake
          docker
          docker-compose
          shellcheck
          shfmt
          vendir
          jq
          ytt
          sqlx-cli
          cargo-nextest
          cargo-audit
          cargo-watch
          reindeer
          gitMinimal
          protobuf
          rover
          pythonEnv
          grpcurl
        ]
        ++ buck2NativeBuildInputs
        ++ lib.optionals pkgs.stdenv.isLinux [
          xvfb-run
          cypress
        ];

      buck2BuildInputs = with pkgs;
        []
        ++ lib.optionals pkgs.stdenv.isDarwin [
          darwin.apple_sdk.frameworks.SystemConfiguration
        ];

      buck2Version = pkgs.buck2.version;
      postPatch = with pkgs; ''
        rg -l '#!(/usr/bin/env|/bin/bash|/bin/sh)' prelude toolchains \
          | while read -r file; do
            patchShebangs --build "$file"
          done

        rg -l '(/usr/bin/env|/bin/bash)' prelude toolchains \
          | while read -r file; do
            substituteInPlace "$file" \
              --replace /usr/bin/env "${coreutils}/bin/env" \
              --replace /bin/bash "${bash}/bin/bash"
          done
      '';

      rustDerivation = {
        pkgName,
        pathPrefix ? "core",
      }:
        pkgs.stdenv.mkDerivation {
          bin_target = pkgName;

          name = pkgName;
          buck2_target = "//${pathPrefix}/${pkgName}";
          src = ./.;
          nativeBuildInputs = buck2NativeBuildInputs;
          inherit postPatch;

          buildPhase = ''
            export HOME="$(dirname $(pwd))/home"
            buck2 build "$buck2_target" --verbose 8

            result=$(buck2 build --show-simple-output "$buck2_target:$bin_target" 2> /dev/null)

            mkdir -p build/$name-$system/bin
            cp -rpv $result build/$name-$system/bin/
          '';

          installPhase = ''
            mkdir -pv "$out"
            cp -rpv "build/$name-$system/bin" "$out/"
          '';
        };

    in
      with pkgs; {
        packages = {
          api = rustDerivation {pkgName = "api";};

          dockerImage = dockerTools.buildImage {
            name = "fundcatchup-dev";
            tag = "latest";

            # Optional base image to bring in extra binaries for debugging etc.
            fromImage = dockerTools.pullImage {
              imageName = "ubuntu";
              imageDigest = "sha256:4c32aacd0f7d1d3a29e82bee76f892ba9bb6a63f17f9327ca0d97c3d39b9b0ee";
              sha256 = "f1661f16a23427d0eda033ffbf7df647a6f71673b78ee24961fae27978691d4f";
              finalImageTag = "mantic-20231011";
              finalImageName = "ubuntu";
            };

            config = {
              Cmd = ["bash"];
              Env = [
                "GIT_SSL_CAINFO=${cacert}/etc/ssl/certs/ca-bundle.crt"
                "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
              ];
            };

            copyToRoot = buildEnv {
              name = "image-root";
              paths =
                nativeBuildInputs
                ++ [
                  bash
                  yq-go
                  google-cloud-sdk
                  openssh
                ];

              pathsToLink = ["/bin"];
            };
          };
        };

        devShells.default = mkShell {
          inherit nativeBuildInputs;
          buildInputs = buck2BuildInputs;

          BUCK2_VERSION = buck2Version;
          COMPOSE_PROJECT_NAME = "fundcatchup-dev";
        };

        formatter = alejandra;
      });
}
