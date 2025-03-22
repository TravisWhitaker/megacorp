self: super:
let
    thisOverlay = import ./overlay.nix;
    toFix = fs : with self.pkgs; lib.foldl' (lib.flip lib.extends) (self: {}) fs;
    megacorpSpecF = pkgs: self: super: import ./corp-packages.nix pkgs;
    withProf = if self.pkgs ? megacorp
               then (if self.pkgs.megacorp ? haskellProfEnabled
                     then self.pkgs.megacorp.haskellProfEnabled
                     else false
                    )
               else false;
    # Always generate position independent code:
    extraCfg = [ "--ghc-option=-fPIC"
                 "--ghc-option=-fexternal-dynamic-refs"
                 "--gcc-option=-fPIC"
                 "--ghc-option=-haddock"
               ];
    # Use these tool versions (can include hlint, fourmolu, etc.):
    megacorpShellToolVersions = {
      cabal = "latest";
      haskell-language-server = "latest";
    };
in rec {
    haskell-nix = super.haskell-nix // {
        overlays = super.overlays ++ [ thisOverlay ];
        compiler = super.haskell-nix.compiler // {
            ghc984 = self.haskell-nix.haskellLib.makeCompilerDeps
            (super.haskell-nix.compiler.ghc984.override
            {
                # Always generate position independent code:
                enableRelocatedStaticLibs = true;
            }) //
            # Not sure why we have to do this, but we do. See
            # https://github.com/input-output-hk/haskell.nix/issues/1895
            {
                dummy-ghc-data = super.haskell-nix.compiler.ghc984.dummy-ghc-data;
                defaultSetup = super.haskell-nix.compiler.ghc984.defaultSetup;
                defaultSetupFor = super.haskell-nix.compiler.ghc984.defaultSetupFor;
            };
        };
        buildHaskellLib = super.buildPackages.haskell-nix.haskellLib;
        # Stackage snapshot version with extra Hackage deps:
        megacorpStackSpec = import ./snapshot.nix;
        # Megacorp's own packages:
        megacorpPkgSpecs = self.pkgs.lib.fix
            (toFix ([(megacorpSpecF self.pkgs)] ++
                (if self.pkgs ? megacorp
                 then (if self.pkgs.megacorp ? haskellPackageOverrides
                       then self.pkgs.megacorp.haskellPackageOverrides
                       else []
                      )
                 else []
                ))
            );
        # Check that Megacorp package specs have the required fields.
        validateMegacorpSpec = n: v:
            let errRep = a :
                throw ( "Haskell package spec for "
                      + n
                      + " missing "
                      + a
                      + " attribute"
                      );
            in
            if (!(v ? "name"))
            then errRep "name"
            else if (!(v ? "src"))
            then errRep "src"
            else if (!(v ? "supportedPlatform"))
            then errRep "supportedPlatform"
            else if (!(v ? "planOverride"))
            then errRep "planOverride"
            else v;
        # The set of Megacorp packages supported on the currently evaluating
        # platform:
        supportedMegacorpPkgSpecs = super.pkgs.lib.filterAttrs
            (_: x: x.supportedPlatform super.pkgs)
            (builtins.mapAttrs
                self.haskell-nix.validateMegacorpSpec
                self.haskell-nix.megacorpPkgSpecs);
        # All Megacorp packages; we need this set for generating a global Hoogle
        # database.
        docMegacorpPkgSpecs =
            builtins.mapAttrs
                self.haskell-nix.validateMegacorpSpec
                self.haskell-nix.megacorpPkgSpecs;
        # planOverrides in Megacorp package specs should recursively override the
        # defaults:
        addMkForce =
            let f = s :
                if builtins.isAttrs s
                then builtins.mapAttrs (_: v: f v) s
                else super.pkgs.lib.mkForce s;
            in f;
        # Setup overrides for a given package spec.
        planOverrideSet = s :
        {
            packages."${s.name}" = self.haskell-nix.addMkForce (s.planOverride super.pkgs);
        };
        # Overrides applied to the Stackage snapshot config:
        megacorpPlanOverrideModBase =
        let ctk =
            if self.pkgs.targetPlatform.isAarch64
            then self.pkgs.megacorp.jetpackPackages_4_3.cudatoolkit.override {stdenv = self.pkgs.stdenv;}
            else self.pkgs.cudaPackages_10_0.cudatoolkit;
            # Note that wherever we change configureFlags, we also add our
            # extraCfg. If we override a package component's config flags here,
            # it won't pick up any later module's top-level configureFlags
            # setting, so we also must add extraCfg here. Should probably fix
            # this in Haskell.nix upstream somehow.
        in
        {
            evalPackages = self.buildPackages;
            # Upstream added this nutty flag recently; it implements something
            # to do with the Cabal planner and if we don't set it globally here
            # nothing works. wtf.
            planned = true;
            packages.X11.components.library.libs = self.pkgs.lib.mkForce
                [ self.pkgs.xorg.libX11
                  self.pkgs.xorg.libXScrnSaver
                  self.pkgs.xorg.libXinerama
                  self.pkgs.xorg.libXrandr
                  self.pkgs.xorg.libXext
                ];
            packages.bindings-GLFW.components.tests."main".buildable =
                self.pkgs.lib.mkForce false;
            packages.bindings-GLFW.components.library.configureFlags =
                self.pkgs.lib.mkForce
                    ([ "-fsystem-glfw"
                       "-fexposenative"
                     ] ++ extraCfg);
            packages.bindings-GLFW.components.library.libs =
                self.pkgs.lib.mkForce
                    [ self.pkgs.libGL
                      self.pkgs.xorg.libX11
                      self.pkgs.xorg.libXcursor
                      self.pkgs.xorg.libXext
                      self.pkgs.xorg.libXfixes
                      self.pkgs.xorg.libXi
                      self.pkgs.xorg.libXinerama
                      self.pkgs.xorg.libXrandr
                      self.pkgs.xorg.libXxf86vm
                      self.pkgs.xorg.libxcb
                      self.pkgs.xorg.libXdmcp
                      self.pkgs.glfw3
                    ];
            packages.bindings-GLFW.components.library.pkgconfig =
                self.pkgs.lib.mkForce [];
            packages.bindings-GLFW.components.library.build-tools =
                self.pkgs.lib.mkForce
                    [ self.pkgs.buildPackages.pkg-config
                    ];
            packages.bindings-libusb.components.library.build-tools =
                self.pkgs.lib.mkForce
                    [ self.pkgs.buildPackages.pkg-config
                    ];
            packages.bindings-libusb.components.library.pkgconfig =
                self.pkgs.lib.mkForce [];
            packages.bindings-libusb.components.library.libs = self.pkgs.lib.mkForce
                [ self.pkgs.libusb1
                ];
            packages.haskeline.components.library.configureFlags =
                (if (self.pkgs.buildPlatform != self.pkgs.targetPlatform)
                 then [ "-f-terminfo" ]
                 else []) ++ extraCfg;
            packages.ffmpeg-light.components.library.libs = [ self.pkgs.ffmpeg ];
            packages.ffmpeg-light.components.library.pkgconfig = self.pkgs.lib.mkForce [ ];
            packages.ffmpeg-light.components.library.build-tools = [ self.pkgs.buildPackages.pkg-config ];
            packages.vector-fftw.components.library.libs = self.pkgs.lib.mkForce [ self.pkgs.fftw ];
            packages.llvm-hs.components.library.preConfigure = ''
                export PATH=${self.pkgs.buildPackages.llvmPackages_9.llvm.dev}/bin:$PATH
                export NIX_CFLAGS_COMPILE=$(sed 's|-isystem ${self.pkgs.llvmPackages_9.llvm.dev}/include||g' <<< $NIX_CFLAGS_COMPILE)
                export NIX_LDFLAGS=$(sed 's|-L${self.pkgs.llvmPackages_9.llvm.lib}/lib||g' <<< $NIX_LDFLAGS)
            '';
            packages.llvm-hs.components.library.libs =
                [ self.pkgs.llvmPackages_9.llvm
                ];
            packages.llvm-hs.components.library.build-tools = self.pkgs.lib.mkForce
                [ self.pkgs.buildPackages.llvmPackages_9.llvm
                  self.pkgs.buildPackages.llvmPackages_9.llvm.dev
                ];
            packages.llvm-hs.components.tests.test.buildable =
                self.pkgs.lib.mkForce (!(self.pkgs.targetPlatform.isAarch64));
            packages.llvm-hs.components.tests.test.libs =
                [ self.pkgs.llvmPackages_9.llvm
                ];
            packages.llvm-hs.components.tests.test.build-tools =
                [ self.pkgs.buildPackages.llvmPackages_9.llvm
                ];
            packages.foreign-lib-standalone-hello = {
              components.library.configureFlags = extraCfg;
            };
            packages.cuda =
                let cfg = [ "--extra-lib-dirs=${ctk}/lib"
                            "--extra-lib-dirs=${ctk}/lib/stubs"
                            "--extra-include-dirs=${ctk}/include"
                          ] ++ (if (ctk ? lib)
                                then [ "--extra-lib-dirs=${ctk.lib}/lib" ]
                                else []
                               )
                            ++ extraCfg;
                in {
                    components.library.build-tools =
                        self.pkgs.lib.mkForce
                            [ self.pkgs.buildPackages.buildPackages.haskell-nix.currentStackage.c2hs.components.exes.c2hs
                            ];
                    components.library.libs = [ctk];
                    components.library.configureFlags = cfg;
                    components.exes."nvidia-device-query".libs = [ctk];
                    components.exes."nvidia-device-query".configureFlags = cfg;
                };
            packages.nvvm.components.library.build-tools =
                self.pkgs.lib.mkForce
                    [ self.pkgs.buildPackages.buildPackages.haskell-nix.currentStackage.c2hs.components.exes.c2hs
                    ];
            packages.nvvm.components.library.libs = [ctk];
            packages.nvvm.components.library.configureFlags =
                (if self.pkgs.targetPlatform.isAarch64
                 then [ "--extra-lib-dirs=${ctk}/lib"
                        "--extra-lib-dirs=${ctk}/lib/stubs"
                        "--extra-include-dirs=${ctk}/include"
                     ]
                 else [ "--extra-lib-dirs=${ctk}/lib"
                        "--extra-lib-dirs=${ctk}/lib"
                        "--extra-lib-dirs=${ctk}/lib/stubs"
                        "--extra-include-dirs=${ctk}/include"
                      ]) ++ extraCfg;
            # See https://gitlab.haskell.org/ghc/ghc/-/issues/20617
            ###packages.accelerate.components.library.ghcOptions = [ "-O0" ];
            ###packages.accelerate-llvm.components.library.ghcOptions = [ "-O0" ];

            packages.ekg.components.library.enableSeparateDataOutput = true;

            packages.halide-haskell.components.tests.halide-haskell-test.build-tools =
                [ self.pkgs.buildPackages.buildPackages.haskell-nix.currentStackage.hspec-discover.components.exes.hspec-discover
                ];

            packages.halide-haskell.components.library.libs = self.pkgs.lib.mkForce
                [ self.pkgs.megacorp.halide
                ];

            packages.vulkan.components.tests.test.libs = self.pkgs.lib.mkForce
                [ self.pkgs.vulkan-headers
                  self.pkgs.vulkan-loader
                ];
        };
        megacorpPlanOverrideMod =
            self.pkgs.lib.foldl
                self.pkgs.lib.recursiveUpdate
                self.haskell-nix.megacorpPlanOverrideModBase
                (builtins.map
                    self.haskell-nix.planOverrideSet
                    (builtins.attrValues self.haskell-nix.supportedMegacorpPkgSpecs));
        # Compute the Haskell.nix plan for a package spec.
        pkgSpecToPlan = s : self.haskell-nix.megacorpPlan
        {
            inherit (s) name src;
        };
        # Compute the vanilla Haskell.nix plan for a package spec, ignoring the
        # Stackage snapshot or module overrides. This is used for
        # platform-agnostic eval during Hoogle database generation.
        pkgSpecToRawPlan = s : self.haskell-nix.megacorpRawPlan
        {
            inherit (s) name src;
        };
        # All Megacorp package plans, as an extras list.
        megacorpPkgDefExtrasList =
            builtins.map self.haskell-nix.pkgSpecToPlan
                         (builtins.attrValues self.haskell-nix.supportedMegacorpPkgSpecs);
        # All Megacorp package plans, disregarding platform support, as an extras
        # list. Used for Hoogle database generation.
        megacorpDocPkgDefExtrasList =
            builtins.map self.haskell-nix.pkgSpecToPlan
                         (builtins.attrValues self.haskell-nix.docMegacorpPkgSpecs);
        # All vanilla Haskell.nix plans for Megacorp packages, used for Hoogle
        # database generation.
        megacorpPkgRawPlans =
            builtins.mapAttrs (_: v: self.haskell-nix.pkgSpecToRawPlan v)
                self.haskell-nix.supportedMegacorpPkgSpecs;
        # The set of all supported packages for the evaluating platform.
        megacorpPkgSet = super.haskell-nix.mkStackPkgSet
        {
            stack-pkgs = self.haskell-nix.megacorpStackSpec;
            pkg-def-extras = self.haskell-nix.megacorpPkgDefExtrasList;
            modules = [self.haskell-nix.megacorpPlanOverrideMod] ++
                      [{configureFlags = extraCfg;}] ++
                      [( if withProf
                         then { enableProfiling = true;
                                enableLibraryProfiling = true;
                              }
                         else {}
                      )];
        };
        # The set of all Megacorp packages regardless of platform support, used
        # for Hoogle database generation.
        megacorpDocPkgSet = super.haskell-nix.mkStackPkgSet
        {
            stack-pkgs = self.haskell-nix.megacorpStackSpec;
            pkg-def-extras = self.haskell-nix.megacorpDocPkgDefExtrasList;
            modules = [self.haskell-nix.megacorpPlanOverrideMod];
        };
        # All Megacorp-hosted packages supported on the evaluating platform.
        allMegacorpPkgs =
            super.pkgs.lib.getAttrs
                (builtins.map (s: s.name)
                              (builtins.attrValues
                                  self.haskell-nix.supportedMegacorpPkgSpecs))
                self.haskell-nix.currentStackage;
        # All Megacorp-hosted packages, regardless of platform support. This is
        # used for Hoogle database generation.
        docMegacorpPkgs =
            super.pkgs.lib.getAttrs
                (builtins.map
                    (s: s.name)
                    (builtins.attrValues
                        (builtins.mapAttrs
                            self.haskell-nix.validateMegacorpSpec
                            self.haskell-nix.megacorpPkgSpecs)))
                self.haskell-nix.docStackage;
        # All of a package's components symlink together. Replaces
        # 'components.all', which was removed upstream.
        allPackageComps = p : self.pkgs.symlinkJoin
        {
            name = ''${p.identifier.name}-${p.identifier.version or ""}'';
            paths = self.haskell-nix.haskellLib.getAllComponents p;
        };
        # The 'all' component of all Megacorp-hosted packages supported by the
        # evaluating platform. This is used for CI builds and caching.
        allMegacorpPkgComps = builtins.mapAttrs
            (_: v: self.haskell-nix.allPackageComps v)
            self.haskell-nix.allMegacorpPkgs;
        # Get the minimal shell environment for the package with the provided name.
        megacorpShell = n : self.haskell-nix.currentStackage.shellFor
        {
            packages = p: [ p."${n}" ];
            withHoogle = false;
            tools = {
              cabal = "latest";
            };
            exactDeps = true;
        };
        # Get the shell environment for the package with the provided name.
        #
        # Note that we have a filter that changes `tools.mytool = "latest"` to
        # instead refer to the latest version that works with our current ghc.
        # If you really really want the actual latest version available (even
        # though it won't build), use "latest!" or specify the version
        # explicitly.
        #
        # Reference
        # https://input-output-hk.github.io/haskell.nix/reference/library.html#shellfor
        shellFor = {
          name
        , ...
        }@attrs0:
        let
          withHoogle = attrs0.withHoogle or false;
          tools = self.pkgs.lib.attrsets.mapAttrs (t: v:
              if v == "latest" || v == {}
              then megacorpShellToolVersions."${t}" or v
              else if v == "latest!" then "latest" else v
            ) (attrs0.tools or {});
          exactDeps = attrs0.exactDeps or true;
          packages = p: [ p."${name}" ];
        in
        self.haskell-nix.currentStackage.shellFor
        (attrs0 // {
            inherit exactDeps packages tools withHoogle;
        });

        allMegacorpShellTools = self.haskell-nix.currentStackage.shellFor {
          packages = ps: with ps; [ hlint ormolu fourmolu ];
          tools = megacorpShellToolVersions;
          exactDeps = true;
        };

        # All shell environments for all Megacorp-hosted packages supported on
        # the evaluating platform. Used for CI testing and cache population.
        allMegacorpShells =
            super.pkgs.lib.attrsets.mapAttrs
                (n: _: self.haskell-nix.megacorpShell n)
                self.haskell-nix.allMegacorpPkgs;
        evalRoots =
          (self.haskell-nix.roots "ghc984")
          // (self.haskell-nix.megacorpPkgSet.config.evalPackages.haskell-nix.roots "ghc984");
        setupMegacorpProject =
            { project
            , sourceRepos
            , src
            }:
            {
                pkgs = project // {
                    extras = hackage: let old = (project.extras hackage).packages; in {
                          packages = super.pkgs.lib.attrsets.mapAttrs (name: value:
                            if builtins.isFunction value
                              then value
                              else {...}@args:
                                let oldPkg = import value args;
                                in (import value args) // {
                                  src = super.pkgs.lib.mkDefault src;
                                }) old;
                    };
                };
            };
        # The unmodified Haskell.nix plan for an Megacorp project.
        megacorpRawPlan = args@{src, name}:
            super.haskell-nix.callCabalToNix args;
        # The Haskell.nix plan for an Megacorp project, building against the
        # current Stackage snapshot.
        megacorpPlan = args@{src, name}:
            let cabal-nix = super.haskell-nix.callCabalToNix args;
                megacorp-plan =
                {
                    # We want to use the packages from Stackage, but the derivation
                    # from cabal's plan:
                    pkgs = hackage:
                    {
                        packages =
                            self.haskell-nix.megacorpPkgSet.config.hsPkgs;
                            #(super.haskell-nix.stackage.${self.haskell-nix.megacorpStackSpec.resolver}
                            #    hackage).packages;
                        compiler = self.haskell-nix.megacorpPkgSet.config.compiler;
                    };
                    extras = hackage: {packages = {"${name}" = cabal-nix;};};
                    modules = [self.haskell-nix.megacorpSysDepsMod];
                };
                plan = self.haskell-nix.setupMegacorpProject
                {
                    project = megacorp-plan;
                    sourceRepos = [];
                    src = src;
                };
            in plan.pkgs.extras;
        # The package set for the current Stackage snapshot, plus all
        # Megacorp-hosted packages supported on the current platform.
        currentStackage = self.haskell-nix.megacorpPkgSet.config.hsPkgs;
        # The pacakge set for the current Stackage snapshot, plus all
        # Megacorp-hosted packages, regardless of platform support. This is used
        # for Hoogle database generation; in that case, we need to be able to do
        # Nix eval for packages not supported on the evaluating platform.
        docStackage = self.haskell-nix.megacorpDocPkgSet.config.hsPkgs;
    };
}
