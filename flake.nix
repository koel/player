{
  description = "Koel Player - Flutter mobile app development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        # Android SDK configuration
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "11.0";
          toolsVersion = "26.1.1";
          platformToolsVersion = "34.0.5";
          buildToolsVersions = [ "34.0.0" "33.0.2" ];
          includeEmulator = true;
          emulatorVersion = "35.1.19";
          platformVersions = [ "36" "35" "34" "33" "31" ];
          includeSources = false;
          includeSystemImages = false;
          systemImageTypes = [ "google_apis_playstore" ];
          abiVersions = [ "x86_64" "arm64-v8a" ];
          cmakeVersions = [ "3.22.1" ];
          includeNDK = true;
          ndkVersions = [ "27.0.12077973" ];
          useGoogleAPIs = false;
          useGoogleTVAddOns = false;
          includeExtras = [
            "extras;google;gcm"
          ];
        };

        androidSdk = androidComposition.androidsdk;

        # Wrapper script for flutter that auto-patches AAPT2
        flutterWrapper = pkgs.writeShellScriptBin "flutter" ''
          # Patch AAPT2 before running flutter
          if [ -d "$HOME/.gradle/caches" ]; then
            find "$HOME/.gradle/caches" -name "aapt2" -type f 2>/dev/null | while read -r aapt2_path; do
              # Check if already patched by looking for nix store in interpreter
              if [ -x "$aapt2_path" ]; then
                current_interp=$(${pkgs.patchelf}/bin/patchelf --print-interpreter "$aapt2_path" 2>/dev/null || echo "")
                if [[ "$current_interp" != /nix/store/* ]]; then
                  chmod +w "$aapt2_path" 2>/dev/null || true
                  ${pkgs.patchelf}/bin/patchelf --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" "$aapt2_path" 2>/dev/null || true
                  ${pkgs.patchelf}/bin/patchelf --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.zlib pkgs.stdenv.cc.cc.lib ]}" "$aapt2_path" 2>/dev/null || true
                fi
              fi
            done
          fi

          # Run the actual flutter command
          exec ${pkgs.flutter}/bin/flutter "$@"
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Flutter wrapper (replaces flutter)
            flutterWrapper
            dart

            # Android development
            androidSdk
            jdk17

            # Build tools
            git
            curl
            unzip
            which
            patchelf

            # For Linux desktop development (optional)
            pkg-config
            cmake
            ninja
            clang
            gtk3

            # Libraries needed for patching
            zlib
            stdenv.cc.cc.lib
          ];

          shellHook = ''
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export JAVA_HOME="${pkgs.jdk17}"

            # Android SDK paths
            export PATH="$ANDROID_HOME/platform-tools:$PATH"
            export PATH="$ANDROID_HOME/tools:$PATH"
            export PATH="$ANDROID_HOME/tools/bin:$PATH"

            # Disable analytics
            export FLUTTER_SUPPRESS_ANALYTICS=true
            export DART_SUPPRESS_ANALYTICS=true

            # Chrome for web development (optional)
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"

            echo "🚀 Koel Player Flutter development environment loaded"
            echo "Flutter version: $(flutter --version | head -n 1)"
            echo "Dart version: $(dart --version 2>&1)"
            echo "Android SDK: $ANDROID_HOME"
            echo ""
            echo "Note: Flutter commands will auto-patch AAPT2 for NixOS compatibility"
            echo ""
            echo "Available commands:"
            echo "  flutter doctor    - Check your environment"
            echo "  flutter run       - Run the app"
            echo "  flutter build     - Build the app"
            echo "  flutter test      - Run tests"
          '';
        };

        # Optional: Define a package for building the app
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "koel-player";
          version = "2.2.4";

          src = ./.;

          buildInputs = [ pkgs.flutter androidSdk ];

          buildPhase = ''
            export HOME=$(mktemp -d)
            flutter pub get
            flutter build apk --release
          '';

          installPhase = ''
            mkdir -p $out
            cp -r build/app/outputs/flutter-apk/*.apk $out/
          '';
        };
      }
    );
}
