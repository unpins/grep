{
  description = "GNU grep as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  outputs = { self, unpins-lib }:
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
          # GNU grep deprecated egrep/fgrep and dropped their pages with the
          # deprecation; only grep.1 is installed.
          aliases = [ { name = "egrep"; noMan = true; } { name = "fgrep"; noMan = true; } ];
        }];
      };
      build = pkgs:
        let
          prepared = pkgs.pkgsStatic.gnugrep.overrideAttrs (old: {
            # Run GNU grep's test suite on native runners (0 failures under
            # static-musl); auto-skips on crosses the build host can't execute.
            doCheck = pkgs.pkgsStatic.gnugrep.stdenv.buildPlatform.canExecute
              pkgs.pkgsStatic.gnugrep.stdenv.hostPlatform;
            patches = (old.patches or [ ]) ++ [ ./patches/argv0-dispatch.patch ];
            postInstall = (old.postInstall or "") + ''
              rm -f "$out/bin/egrep" "$out/bin/fgrep"
            '';
          });
        in
        prepared;
      # -lbcrypt: gnulib getrandom needs BCryptGenRandom (same as sed cross-mingw).
      windowsBuild = pkgs:
        let
          cross = unpins-lib.lib.mingwStaticCross pkgs;
          patched = cross.gnugrep.overrideAttrs (old: {
            NIX_LDFLAGS = (old.NIX_LDFLAGS or "") + " -lbcrypt";
            patches = (old.patches or [ ]) ++ [ ./patches/argv0-dispatch.patch ];
            postInstall = (old.postInstall or "") + ''
              rm -f "$out/bin/egrep" "$out/bin/fgrep"
            '';
          });
        in
        patched;
    };
}
