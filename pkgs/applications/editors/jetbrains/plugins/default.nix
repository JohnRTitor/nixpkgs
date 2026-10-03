{
  # keep-sorted start
  autoPatchelfHook,
  callPackage,
  darwin,
  fetchurl,
  fetchzip,
  glib,
  gnugrep,
  lib,
  stdenv,
  # keep-sorted end
}:
{
  tests = callPackage ./tests.nix { };

  addPlugins =
    ide: unprocessedPlugins:
    let
      processPlugin =
        plugin:
        # We can remove this check and just assume plugins to be derivations starting with 26.11.
        lib.throwIfNot (lib.isDerivation plugin)
          "addPlugins no longer supports resolving plugins by name or id strings. Please supply a derivation instead"
          plugin;

      plugins = map processPlugin unprocessedPlugins;

      # Plugins that a previous `addPlugins` call already linked into `ide`.
      # They are already present in the copy made below, so they must not be
      # linked again, but they have to be forwarded to `passthru.addPlugins`
      # implementations because those rebuild the IDE from scratch.
      previousPlugins = ide.plugins or [ ];

      # Directory inside `$out` holding the IDE's `bin/` and `plugins/`
      # directories. `mkJetBrainsProduct` installs the payload to `$out/$pname`
      # and sets `meta.mainProgram` to `$pname`, so that is the default. IDEs
      # with a different layout can point elsewhere by setting
      # `passthru.pluginsRootDir`, e.g. `android-studio` keeps its payload at
      # the root of its output.
      pluginsRootDir =
        ide.pluginsRootDir or (
          if stdenv.hostPlatform.isDarwin then
            "Applications/${
              lib.escapeShellArg (
                ide.product
                  or (throw "jetbrains.plugins.addPlugins: '${ide.pname or ide.name}' does not expose a `product` attribute, which is needed to locate its plugins on Darwin. Use an IDE built by `jetbrains.mkJetBrainsProduct`, or set `passthru.pluginsRootDir`.")
              )
            }.app/Contents"
          else
            ide.meta.mainProgram
        );

      mkWithPlugins = stdenv.mkDerivation (finalAttrs: {
        pname = finalAttrs.meta.mainProgram + "-with-plugins";
        version = ide.version;
        src = ide;
        dontInstall = true;
        dontStrip = true;
        passthru = {
          inherit pluginsRootDir;
          plugins = plugins ++ previousPlugins;
        }
        # Keep delegating when plugins are added to an already-wrapped IDE
        # in more than one step.
        // lib.optionalAttrs (ide ? addPlugins) {
          addPlugins = ide.addPlugins;
        };
        newPlugins = plugins;
        disallowedReferences = [ ide ];
        # `mkJetBrainsProduct` IDEs are patchelf-able, but IDEs shipping
        # binaries for a foreign platform (e.g. `android-studio`, which
        # bundles Android system libraries) are not. Those opt out via
        # `passthru.pluginsUseAutoPatchelf = false`.
        useAutoPatchelf = ide.pluginsUseAutoPatchelf or true;
        dontPatchELF = !finalAttrs.useAutoPatchelf;
        nativeBuildInputs =
          (lib.optional (stdenv.hostPlatform.isLinux && finalAttrs.useAutoPatchelf) autoPatchelfHook)
          # The buildPhase hook rewrites the binary, which invaliates the code
          # signature. Add the fixup hook to sign the output.
          ++ (lib.optional stdenv.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook)
          ++ [ gnugrep ]
          ++ (ide.nativeBuildInputs or [ ]);
        buildInputs = lib.unique ((ide.buildInputs or [ ]) ++ [ glib ]);

        inherit (ide) meta;

        buildPhase = ''
          cp -r ${ide} $out
          chmod +w -R $out
          rm -f $out/${pluginsRootDir}/plugins/plugin-classpath.txt

          (
            shopt -s nullglob

            IFS=' ' read -ra pluginArray <<< "$newPlugins"
            for plugin in "''${pluginArray[@]}"; do
              pluginfiles=($plugin)
              if [[ "$plugin" == *.jar ]]; then
                # if the plugin contains a single jar file, link it directly into the plugins folder
                ln -s "$plugin" $out/${pluginsRootDir}/plugins/
              else
                # otherwise link the plugin directory itself
                ln -s "$plugin" -t $out/${pluginsRootDir}/plugins/
              fi
            done

            for exe in $out/${pluginsRootDir}/bin/*; do
              if [ -x "$exe" ] && ( file "$exe" | grep -q 'text' ); then
                substituteInPlace "$exe" --replace-quiet '${ide}' $out
              fi
            done

            # The launcher loop above covers the common case, but wrappers can
            # also be nested elsewhere in the tree (e.g. the LLDB frontend
            # shipped inside the Android NDK plugin). Point those at the copy
            # too, otherwise the plugins linked above are shadowed by the
            # original payload and `disallowedReferences` trips.
            # `-r` (not `-R`) keeps grep from descending into symlinks, which
            # would reach outside of this output.
            while IFS= read -r -d $'\0' wrapped; do
              substituteInPlace "$wrapped" --replace-quiet '${ide}' $out
            done < <(grep -rlZ --binary-files=without-match -F '${ide}' $out)
          )
        '';
      });
    in
    # Not every package is the JetBrains payload itself. Some IDEs, such as
    # `android-studio`, are only a thin wrapper whose payload lives in a
    # separate store path and whose launcher is generated at build time, so
    # copying `ide` cannot inject anything into the program that actually gets
    # executed. Those packages implement `passthru.addPlugins` instead: it is
    # given every plugin that should be installed and returns the wrapped IDE.
    if ide ? addPlugins then ide.addPlugins (plugins ++ previousPlugins) else mkWithPlugins;
}
