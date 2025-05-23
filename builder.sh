source $stdenv/setup

myPnpmConfigHook() {
    echo "Executing myPnpmConfigHook"

    if [ -n "${pnpmRoot-}" ]; then
      pushd "$pnpmRoot"
    fi

    if [ -z "${pnpmDeps-}" ]; then
      echo "Error: 'pnpmDeps' must be set when using pnpmConfigHook."
      exit 1
    fi

    echo "Configuring pnpm store"

    export HOME=$(mktemp -d)
    export STORE_PATH=$(mktemp -d)

    cp -Tr "$pnpmDeps" "$STORE_PATH"
    chmod -R +w "$STORE_PATH"


    # If the packageManager field in package.json is set to a different pnpm version than what is in nixpkgs,
    # any pnpm command would fail in that directory, the following disables this
    pushd ..
    pnpm config set manage-package-manager-versions false
    popd

    pnpm config set store-dir "$STORE_PATH"

    if [[ -n "$pnpmWorkspace" ]]; then
        echo "'pnpmWorkspace' is deprecated, please migrate to 'pnpmWorkspaces'."
        exit 2
    fi

    echo "Installing dependencies"
    if [[ -n "$pnpmWorkspaces" ]]; then
        local IFS=" "
        for ws in $pnpmWorkspaces; do
            pnpmInstallFlags+=("--filter=$ws")
        done
    fi

    runHook prePnpmInstall

    # pushd /home/invariance/programming/web-command
    # pnpm run start
    # popd

    pnpm install \
        --offline \
        --ignore-scripts \
        "${pnpmInstallFlags[@]}" \
        --frozen-lockfile

    echo "Starting web-command"
    nix --extra-experimental-features 'nix-command flakes' run github:Invariance-NaN/web-command
    echo "web-command done"

    pnpm config set loglevel debug
    python3 --version
    pnpm rb --stream --reporter=append-only

    echo "Patching scripts"

    patchShebangs node_modules/{*,.*}

    if [ -n "${pnpmRoot-}" ]; then
      popd
    fi

    echo "Finished pnpmConfigHook"
}

postConfigureHooks=(myPnpmConfigHook)

genericBuild
