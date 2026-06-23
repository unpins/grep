{
  description = "GNU grep as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  outputs = { self, unpins-lib }:
    let
      # GNU grep 3.x dropped argv[0] mode dispatch (egrep/fgrep ship as
      # scripts that exec `grep -E`/`-F`). We drop those scripts and ship the
      # names as aliases, so restore the dispatch in the binary: invoked as
      # *egrep/*fgrep, imply -E/-F.
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
        inferLinkInputs = true;
        # Also fold into the Windows (mingw PE32+) mega: build the windows
        # artifact through the unpin-llvm engine and emit a bitcode module.
        # Validated end-to-end (engine cross-build → PE32+ + module.bc; the
        # grep+sed mega runs grep/egrep/fgrep on a real Windows host).
        windows = true;
        # Also fold into the darwin (Mach-O) mega: engine cross-build from linux
        # emits a darwin bitcode module (1 external unpin__grep__grep_main),
        # validated running on macOS. The mega links it via ld64.lld.
        darwin = true;
        programs = [{
          name = "grep";
          aliases = [ "egrep" "fgrep" ];
        }];
      };
      build = pkgs:
        let
          prepared = pkgs.pkgsStatic.gnugrep.overrideAttrs (old: {
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
      # darwin module build: same restoreArgv0Dispatch as native/windows so
      # egrep/fgrep imply -E/-F inside the mega. `pkgs` is the engine+static
      # darwin cross set (darwinStaticCross already applied), so reach the static
      # gnugrep directly — no pkgsStatic/mingwStaticCross wrapper here.
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
