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
  };
  outputs = { self, nixpkgs, nixCats, ... }@inputs: let
    inherit (nixCats) utils;
    luaPath = "${./.}";
    forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
    extra_pkg_config = {
      allowUnfree = true;
    };
    inherit (forEachSystem (system: let
      dependencyOverlays = [
        (utils.standardPluginOverlay inputs)
      ];
    in { inherit dependencyOverlays; })) dependencyOverlays;

    categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
      lspsAndRuntimeDeps = {
        general = with pkgs; [

        ];
      };
      startupPlugins = {
        general = with pkgs.vimPlugins; [
          lze
        ];
        gitPlugins = with pkgs.neovimPlugins; [
          modus
        ];
      };

      optionalPlugins = {
        gitPlugins = with pkgs.neovimPlugins; [
        ];
        general = with pkgs.vimPlugins; [ 
            nvim-treesitter-textobjects
            nvim-treesitter.withAllGrammars
	];
      };

      sharedLibraries = {
        general = with pkgs; [
        ];
      };

      environmentVariables = {
        test = {
          CATTESTVAR = "It worked!";
        };
      };
      extraWrapperArgs = {
        test = [
          '' --set CATTESTVAR2 "It worked again!"''
        ];
      };

      extraPython3Packages = {
        test = (_:[]);
      };
      extraLuaPackages = {
        test = [ (_:[]) ];
      };
    };
    packageDefinitions = {
      nvim = {pkgs , ... }: {
        settings = {
          wrapRc = true;
          aliases = [ "vi" ];
          neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
        };
        categories = {
          general = true;
          always = true;
          telescope = true;
          customPlugins = true;
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
  forEachSystem (system: let
    nixCatsBuilder = utils.baseBuilder luaPath {
      inherit nixpkgs system dependencyOverlays extra_pkg_config;
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
        shellHook = ''
        '';
      };
    };

  }) // {
    overlays = utils.makeOverlays luaPath {
      inherit nixpkgs dependencyOverlays extra_pkg_config;
    } categoryDefinitions packageDefinitions defaultPackageName;

    nixosModules.default = utils.mkNixosModules {
      inherit defaultPackageName dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
    };
    homeModule = utils.mkHomeModules {
      inherit defaultPackageName dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
    };
    inherit utils;
    inherit (utils) templates;
  };
}
