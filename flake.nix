{
  description = "A featureful and accessible item and recipe viewer for Minecraft";

  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.systems.flake = false;
  inputs.systems.url = "github:nix-systems/default";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { config, lib, ... }:
      let
        emiGradleProperties = lib.strings.readFile ./gradle.properties;
        emiMinecraftVersion = lib.lists.elemAt (lib.strings.match "(.*\n)?minecraft_version=([^\n]+)(\n.*)?" emiGradleProperties) 1;
        emiModVersion = lib.lists.elemAt (lib.strings.match "(.*\n)?mod_version=([^\n]+)(\n.*)?" emiGradleProperties) 1;
        emiVersion = "${emiModVersion}+${emiMinecraftVersion}";
        lastModifiedDate =
          let
            inherit (lib.lists) elemAt;
            matches = lib.strings.match "([0-9]+)([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})" inputs.self.sourceInfo.lastModifiedDate;
          in
          {
            year = elemAt matches 0;
            month = elemAt matches 1;
            day = elemAt matches 2;
            hour = elemAt matches 3;
            minute = elemAt matches 4;
            second = elemAt matches 5;
          };
        selfUnstableVersion = "unstable-${lastModifiedDate.year}-${lastModifiedDate.month}-${lastModifiedDate.day}";
        storePath =
          let
            inherit (builtins) appendContext;
          in
          path: appendContext path { ${path} = { path = true; }; };
        flakeConfig = config;
      in
      {
        imports = [
          inputs.treefmt-nix.flakeModule
        ];
        config.flake.overlays.emiPackages = finalPkgs: prevPkgs: {
          emiPackages = finalPkgs.callPackage (
            args@{
              attrPathForPackage ? null,
              generateSplicesForMkScope,
              lib,
              makeScopeWithSplicing',
              splicePackages,
              ...
            }:
            let
              attrPathForPackage = if builtins.isNull args.attrPathForPackage or null then [ "emiPackages" ] else args.attrPathForPackage;
            in
            makeScopeWithSplicing' {
              extra = spliced0: spliced0.extraPackages;
              f =
                finalEmiPackages:
                let
                  inherit (finalEmiPackages) callPackage callParentPackage;
                in
                {
                  callParentPackage = finalPkgs.callPackage;
                  emi-unstable = callPackage (
                    {
                      attrPathForPackage,
                      gradle,
                      lib,
                      nix-gitignore,
                      stdenv,
                      ...
                    }:
                    stdenv.mkDerivation (finalAttrs: {
                      pname = "emi";
                      version = "${finalAttrs.modVersion}-${selfUnstableVersion}+${finalAttrs.minecraftVersion}";
                      modVersion = emiModVersion;
                      minecraftVersion = emiMinecraftVersion;

                      strictDeps = true;

                      src = nix-gitignore.gitignoreSource ''
                        /gradle/wrapper
                        /gradlew
                        /gradlew.bat
                      '' ./.;

                      nativeBuildInputs = [ gradle ];

                      mitmCache = gradle.fetchDeps {
                        inherit (finalAttrs) pname;
                        attrPath = lib.strings.concatStringsSep "." attrPathForPackage;
                        data = ./gradle-deps.json;
                      };

                      # this is required for using mitm-cache on Darwin
                      __darwinAllowLocalNetworking = true;

                      gradleFlags = [
                        "-Dfile.encoding=utf-8"
                      ];

                      # defaults to "assemble"
                      gradleBuildTask = [
                        ":fabric:build"
                        ":neoforge:build"
                        # ":forge:build"
                      ];

                      installPhase = ''
                        runHook preInstall

                        local builtLibs=(
                          ./fabric/build/libs/"emi-''${modVersion}''${RELEASE:--SNAPSHOT}+''${minecraftVersion}+fabric"{,-api}.jar
                          ./neoforge/build/libs/"emi-''${modVersion}''${RELEASE:--SNAPSHOT}+''${minecraftVersion}+neoforge"{,-api}.jar
                          # ./forge/build/libs/"emi-''${modVersion}''${RELEASE:--SNAPSHOT}+''${minecraftVersion}+forge"{,-api}.jar
                        )
                        install -Dm 644 -t "$out/share/emi" "''${builtLibs[@]}"

                        runHook postInstall
                      '';

                      meta = {
                        description = "A featureful and accessible item and recipe viewer for Minecraft";
                        homepage = "https://github.com/emilyploszaj/emi";
                        license = [ lib.licenses.mit ];
                        maintainers = [ ];
                        platforms = lib.platforms.all;
                        sourceProvenance = [
                          lib.sourceTypes.fromSource
                          lib.sourceTypes.binaryBytecode # mitm cache
                        ];
                      };
                    })
                  ) { attrPathForPackage = attrPathForPackage ++ [ "emi-unstable" ]; };
                  emi-minimalDevShell = callPackage (
                    {
                      jdk_headless,
                      mkShell,
                      stdenv,
                      ...
                    }:
                    mkShell.override { inherit stdenv; } {
                      __structuredAttrs = true;
                      strictDeps = true;

                      nativeBuildInputs = [
                        jdk_headless
                      ];
                    }
                  ) { attrPathForPackage = attrPathForPackage ++ [ "emi-minimalDevShell" ]; };
                  emi-devShell = callPackage (
                    {
                      addDriverRunpath,
                      alsa-lib,
                      emi-minimalDevShell,
                      eclipses,
                      flite,
                      glfw3-minecraft,
                      jdk,
                      lib,
                      libGL,
                      libX11,
                      libXcursor,
                      libXext,
                      libXrandr,
                      libXxf86vm,
                      libjack2,
                      libpulseaudio,
                      libusb1,
                      mkShell,
                      openal,
                      pciutils,
                      pipewire,
                      stdenv,
                      udev,
                      vulkan-loader,
                      xrandr,
                      ...
                    }:
                    let
                      emi-minimalDevShell' = emi-minimalDevShell.override {
                        jdk_headless = jdk;
                      };
                      env' = emi-minimalDevShell'.env;
                    in
                    mkShell.override { inherit stdenv; } {
                      __structuredAttrs = true;
                      strictDeps = true;

                      inputsFrom = [
                        emi-minimalDevShell'
                      ];
                      nativeBuildInputs = [
                        eclipses.eclipse-java
                      ];
                      buildInputs = [
                        pciutils
                        xrandr
                      ];
                      env = env' // {
                        LD_LIBRARY_PATH =
                          lib.makeLibraryPath [
                            addDriverRunpath.driverLink

                            ## native versions
                            glfw3-minecraft
                            openal

                            ## openal
                            alsa-lib
                            libjack2
                            libpulseaudio
                            pipewire

                            ## glfw
                            libGL
                            libX11
                            libXcursor
                            libXext
                            libXrandr
                            libXxf86vm

                            udev # oshi

                            vulkan-loader # VulkanMod's lwjgl

                            flite

                            libusb1
                          ]
                          + (if env'.LD_LIBRARY_PATH or "" == "" then "" else ":${env'.LD_LIBRARY_PATH}");
                      };
                    }
                  ) { attrPathForPackage = attrPathForPackage ++ [ "emi-devShell" ]; };
                  extraPackages = callParentPackage (
                    {
                      gradle_8,
                      jdk21,
                      jdk21_headless,
                      ...
                    }:
                    {
                      gradle = gradle_8;
                      jdk = jdk21;
                      jdk_headless = jdk21_headless;
                    }
                  ) { attrPathForPackage = attrPathForPackage ++ [ "extraPackages" ]; };
                  generateSplicesForMkScope = attrPath: generateSplicesForMkScope (attrPathForPackage ++ attrPath);
                  makeScopeWithSplicing = lib.customisation.makeScopeWithSplicing splicePackages finalEmiPackages.newScope;
                  makeScopeWithSplicing' = lib.customisation.makeScopeWithSplicing' {
                    inherit splicePackages;
                    inherit (finalEmiPackages) newScope;
                  };
                };
              otherSplices = generateSplicesForMkScope attrPathForPackage;
            }
          ) { };
        };
        config.perSystem =
          {
            config,
            pkgs,
            system,
            ...
          }:
          {
            config._module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = false;
              overlays = [
                flakeConfig.flake.overlays.emiPackages
              ];
            };
            config.apps.emiUpdateScript.type = "app";
            config.apps.emiUpdateScript.program =
              (pkgs.__splicedPackages.linkFarm "emiUpdateScript" [
                {
                  name = "bin/update-script";
                  path = pkgs.__splicedPackages.emiPackages.emi-unstable.mitmCache.updateScript;
                }
              ]).overrideAttrs
                (prevAttrs: {
                  meta = prevAttrs.meta or { } // {
                    mainProgram = "update-script";
                  };
                });
            config.devShells.emi-minimal = pkgs.__splicedPackages.emiPackages.emi-minimalDevShell;
            config.devShells.emi = pkgs.__splicedPackages.emiPackages.emi-devShell;
            config.devShells.default = pkgs.__splicedPackages.emiPackages.callPackage (
              {
                emi-devShell,
                mkShell,
                stdenv,
                ...
              }:
              let
                emi-devShell' = emi-devShell.override { inherit mkShell stdenv; };
              in
              mkShell.override { inherit stdenv; } {
                __structuredAttrs = true;
                strictDeps = true;

                inputsFrom = [
                  emi-devShell'
                  config.treefmt.build.devShell
                ];

                env = emi-devShell'.env;
              }
            ) { };
            config.legacyPackages.nixpkgs = lib.dontRecurseIntoAttrs pkgs;
            config.treefmt = {
              config.programs.nixfmt.enable = true;
              config.projectRootFile = ".github/ISSUE_TEMPLATE/emi-bug.md";
            };
          };
        config.systems = import inputs.systems;
      }
    );
}
