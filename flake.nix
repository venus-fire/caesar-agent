{
  description = "Caesar autonomous research agent — Nix dev shell";

  # Dev/iteration shell only. Caesar is NOT built declaratively in Nix: the
  # systemd service copies this source into a writable state dir and runs
  # web_server/launch.sh, which bootstraps the Python venv + Next.js UI itself
  # (chromadb / llama-index / mem0ai / litellm + a Next.js prod build are too
  # heavy and fragile to package in Nix). This shell just gives you that
  # launcher's toolchain to run it and develop.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (s:
        f (import nixpkgs { system = s; }));
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs;
            [ python3 nodejs uv curl git gnutar util-linux lsof ncurses ];
          # chroma/numpy pip wheels need libz + libstdc++ at load time and
          # NixOS has no /usr/lib — mirror the service's LD_LIBRARY_PATH fix.
          LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib";
        };
      });
    };
}
