{
  description = "Minimalistic web UI for Taskwarrior";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-linux" ];
      packageSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkTaskwarriorWeb = pkgs: pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "taskwarrior-web";
        version = "2.0.1";

        src = self;
        cargoLock.lockFile = ./Cargo.lock;

        npmDeps = pkgs.fetchNpmDeps {
          src = ./frontend;
          hash = "sha256-tyUSP6khP2lxpHzdRYDy0BgOa2STk8q1r9zOZcTIiPY=";
        };
        npmRoot = "frontend";

        nativeBuildInputs = [
          pkgs.nodejs
          pkgs.npmHooks.npmConfigHook
        ];
        nativeCheckInputs = [ pkgs.bash ];

        env.TASKWARRIOR_WEB_SKIP_NPM_INSTALL = "1";

        meta = {
          description = "Minimalistic web UI for Taskwarrior";
          homepage = "https://github.com/prodzombie/taskwarrior-web";
          license = pkgs.lib.licenses.mit;
          mainProgram = "taskwarrior-web";
          platforms = pkgs.lib.platforms.linux;
        };
      });
    in
    {
      packages = nixpkgs.lib.genAttrs packageSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          taskwarrior-web = mkTaskwarriorWeb pkgs;
        in
        {
          inherit taskwarrior-web;
          default = taskwarrior-web;
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          taskwarrior-web = mkTaskwarriorWeb pkgs;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.cargo
              pkgs.clippy
              pkgs.nodejs
              pkgs.rustc
              pkgs.rustfmt
              pkgs.taskwarrior3
            ];

            npm_config_cache = taskwarrior-web.npmDeps;
            TASKWARRIOR_WEB_SKIP_NPM_INSTALL = "1";

            shellHook = ''
              if [[ ! -d frontend/node_modules ]]; then
                npm ci --prefix frontend --offline
              fi
            '';
          };
        });
    };
}
