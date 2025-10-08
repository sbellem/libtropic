{
  description = "Nix flake to build libtropic";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/20c4598c84a671783f741e02bf05cbfaf4907cff";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        fs = pkgs.lib.fileset;
        sourceFiles = fs.unions [
          ./.clang-format
          ./CMakeLists.txt
          ./TROPIC01_fw_update_files
          ./cmake
          ./docs
          ./examples
          ./hal
          ./include
          ./keys
          ./mkdocs.yml
          ./provisioning_data
          ./scripts
          ./setup_env
          ./src
          ./tests
          ./tropic01_model
          ./ts_sw_setup.yml
          ./vendor
        ];
        src = fs.toSource {
          root = ./.;
          fileset = sourceFiles;
        };

        pname       = "libtropic";
        version     = "2.0.0";

      in {
      devShell = with pkgs; mkShell {
        nativeBuildInputs = [ cmake ];
        buildInputs = [
          gcc
          python313
          python313Packages.cryptography
        ];
        shellHook = ''
          echo "Development environment for libtropic is ready."
        '';
      };

      packages.libtropic = with pkgs; stdenv.mkDerivation {
        inherit pname version;
        src = src;

        nativeBuildInputs = [ cmake ];
        buildInputs = [
          gcc
          python313
          python313Packages.cryptography
        ];

        cmakeFlags = [
          "-DLT_BUILD_EXAMPLES=ON"
          "-DLT_CRYPTO=trezor_crypto"
          "-DCMAKE_VERBOSE_MAKEFILE=ON"
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib $out/include

          # Install the static library
          cp /build/source/build/libtropic.a $out/lib/

          # Install headers
          cp -r /build/source/include/* $out/include/

          runHook postInstall
        '';
      };

      defaultPackage = self.packages.${system}.libtropic;
    });
}
