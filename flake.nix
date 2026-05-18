{
  description = "Standalone build of GNU grep";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # pkgsStatic.gnugrep ships bin/grep as ELF plus bin/{egrep,fgrep} as 1-line
  # shell wrappers (`exec /nix/store/...-grep -E "$@"`). The wrappers hardcode
  # the nix-store path of grep so they break the second the closure isn't
  # present on the user's machine.
  #
  # GNU grep dispatches its mode from argv[0]: if the basename ends in `egrep`
  # or `fgrep`, it implies `-E` / `-F`. So we drop the wrappers and register
  # the names as UNPIN_META aliases; `unpin install grep` materialises them as
  # argv[0]-shims that re-exec the grep binary with the original name preserved.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "grep";
      pkgsAttr = "gnugrep";
      smoke = [ "--version" ];
      smokePattern = "GNU grep";
      build = pkgs:
        let
          prepared = pkgs.pkgsStatic.gnugrep.overrideAttrs (old: {
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
      # Same gnulib-getrandom / BCryptGenRandom missing -lbcrypt issue as
      # sed cross-mingw. Plus egrep/fgrep wrappers (shell scripts pointing
      # at the nix-store grep path) are dropped — withAliases re-creates
      # the names as UNPIN_META aliases that argv[0]-dispatch back to
      # grep.exe.
      windowsBuild = pkgs:
        let
          cross = unpins-lib.lib.mingwStaticCross pkgs;
          patched = cross.gnugrep.overrideAttrs (old: {
            NIX_LDFLAGS = (old.NIX_LDFLAGS or "") + " -lbcrypt";
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
