{
  description = "GNU grep as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  outputs = { self, unpins-lib }:
    let
      # GNU grep 3.x dropped argv[0] dispatch — egrep/fgrep became wrapper
      # scripts. We ship them as aliases, so re-add it: invoked as
      # *egrep/*fgrep ⇒ -E/-F.
      restoreArgv0Dispatch = ''
        cat > grep-argv0.inc <<'INC'
          if (argv[0])
            {
              char const *b__ = argv[0];
              for (char const *p__ = argv[0]; *p__; p__++)
                if (*p__ == '/' || *p__ == '\\') b__ = p__ + 1;
              idx_t bl__ = strlen (b__);
              if (bl__ > 4 && STREQ (b__ + bl__ - 4, ".exe")) bl__ -= 4;
              if (bl__ >= 5 && memcmp (b__ + bl__ - 5, "egrep", 5) == 0)
                matcher = setmatcher ("egrep", matcher);
              else if (bl__ >= 5 && memcmp (b__ + bl__ - 5, "fgrep", 5) == 0)
                matcher = setmatcher ("fgrep", matcher);
            }
        INC
        sed -i '/initialize_main (&argc, &argv);/r grep-argv0.inc' src/grep.c
        rm grep-argv0.inc
      '';
    in
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "grep";
      pkgsAttr = "gnugrep";
      smoke = [ "--version" ];
      smokePattern = "GNU grep";
      engine = "unpin-llvm";
      multicall = {
        windows = true;
        programs = [{
          name = "grep";
          aliases = [ "egrep" "fgrep" ];
        }];
      };
      build = pkgs:
        let
          prepared = pkgs.pkgsStatic.gnugrep.overrideAttrs (old: {
            # Run GNU grep's test suite on native runners (0 failures under
            # static-musl); auto-skips on crosses the build host can't execute.
            doCheck = pkgs.pkgsStatic.gnugrep.stdenv.buildPlatform.canExecute
              pkgs.pkgsStatic.gnugrep.stdenv.hostPlatform;
            nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ pkgs.buildPackages.perl ];
            postPatch = (if (old.postPatch or null) == null then "" else old.postPatch) + restoreArgv0Dispatch;
            postInstall = (old.postInstall or "") + ''
              rm -f "$out/bin/egrep" "$out/bin/fgrep"
            '';
          });
        in
        unpins-lib.lib.withAliases pkgs
          {
            primary = "grep";
            aliases = [ "egrep" "fgrep" ];
          }
          prepared;
      # darwin: `pkgs` is already the static darwin set, so reach gnugrep
      # directly (no pkgsStatic wrapper).
      darwinBuild = pkgs:
        pkgs.gnugrep.overrideAttrs (old: {
          postPatch = (if (old.postPatch or null) == null then "" else old.postPatch) + restoreArgv0Dispatch;
          postInstall = (old.postInstall or "") + ''
            rm -f "$out/bin/egrep" "$out/bin/fgrep"
          '';
        });
      # -lbcrypt: gnulib getrandom needs BCryptGenRandom (same as sed cross-mingw).
      windowsBuild = pkgs:
        let
          cross = unpins-lib.lib.mingwStaticCross pkgs;
          patched = cross.gnugrep.overrideAttrs (old: {
            NIX_LDFLAGS = (old.NIX_LDFLAGS or "") + " -lbcrypt";
            postPatch = (if (old.postPatch or null) == null then "" else old.postPatch) + restoreArgv0Dispatch;
            postInstall = (old.postInstall or "") + ''
              rm -f "$out/bin/egrep" "$out/bin/fgrep"
            '';
          });
        in
        unpins-lib.lib.withAliases pkgs
          {
            primary = "grep.exe";
            aliases = [ "egrep" "fgrep" ];
          }
          patched;
    };
}
