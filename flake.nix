{
  description = "Neovim config using BirdeeHub's nixCats-nvim";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    plugins-modus = {
      flake = false;
      url = "github:miikanissi/modus-themes.nvim";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";

  };
  outputs =
    {
      nixpkgs,
      nixCats,
      treefmt-nix,
      systems,
      ...
    }@inputs:
    let
      inherit (nixCats) utils;
      luaPath = "${./.}";
      forEachSystem = utils.eachSystem [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
      ];
      newForEachSystem =
        f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = newForEachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
      extra_pkg_config = {
        allowUnfree = true;
      };
      inherit
        (forEachSystem (
          _system:
          let
            dependencyOverlays = [
              (utils.standardPluginOverlay inputs)
            ];
          in
          {
            inherit dependencyOverlays;
          }
        ))
        dependencyOverlays
        ;

      categoryDefinitions =
        { pkgs, ... }:
        {
          lspsAndRuntimeDeps = {
            general = with pkgs; [

            ];
          };
          startupPlugins = {
            general = with pkgs.vimPlugins; [
              lze
              vimtex
            ];
            gitPlugins = with pkgs.neovimPlugins; [
              modus
            ];
          };

          optionalPlugins = {
            gitPlugins =
              with pkgs.neovimPlugins;
              [
              ];
            general = {
              treesitter = with pkgs.vimPlugins; [
                nvim-treesitter-textobjects
                nvim-treesitter.withAllGrammars
              ];
              always = with pkgs.vimPlugins; [
                lualine-nvim
              ];
            };
          };

          sharedLibraries = {
            general =
              with pkgs;
              [
              ];
          };

          environmentVariables = {
            test = {
              CATTESTVAR = "It worked!";
            };
          };
          extraWrapperArgs = {
            test = [
              ''--set CATTESTVAR2 "It worked again!"''
            ];
          };

          extraPython3Packages = {
            test = _: [ ];
          };
          extraLuaPackages = {
            test = [ (_: [ ]) ];
          };
        };
      packageDefinitions = {
        nvim =
          { pkgs, ... }:
          {
            settings = {
              wrapRc = true;
              aliases = [ "vi" ];
              neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
            };
            categories = {
              general = true;
              gitPlugins = true;
              test = true;
              example = {
                youCan = "add more than just booleans";
                toThisSet = [
                  "and the contents of this categories set"
                  "will be accessible to your lua with"
                  "nixCats('path.to.value')"
                  "see :help nixCats"
                ];
              };
            };
          };
      };
      defaultPackageName = "nvim";
    in
    forEachSystem (
      system:
      let
        nixCatsBuilder = utils.baseBuilder luaPath {
          inherit
            nixpkgs
            system
            dependencyOverlays
            extra_pkg_config
            ;
        } categoryDefinitions packageDefinitions;
        defaultPackage = nixCatsBuilder defaultPackageName;
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = utils.mkAllWithDefault defaultPackage;

        devShells = {
          default = pkgs.mkShell {
            name = defaultPackageName;
            packages = [ defaultPackage ];
            inputsFrom = [ ];
            shellHook = '''';
          };
        };

      }
    )
    // {
      formatter = newForEachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      overlays = utils.makeOverlays luaPath {
        inherit nixpkgs dependencyOverlays extra_pkg_config;
      } categoryDefinitions packageDefinitions defaultPackageName;

      nixosModules.default = utils.mkNixosModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
      homeModule = utils.mkHomeModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
    };
}
