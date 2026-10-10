# Helium browser flake

Nix flake for [Helium](https://helium.computer/) the minimal and private,
Chromium-based web browser by [imputnet](https://github.com/imputnet) from the
official prebuilt Linux binaries, and keeps the version and hashes up to date
automatically with GitHub Actions.

## Quick start

    nix run github:yashsio/helium-browser-flake

If this repository is cloned locally, `nix run .` works too.

## Installation

### Run without installing

    nix run github:yashsio/helium-browser-flake

### Imperative install

    nix profile install github:yashsio/helium-browser-flake

The `helium` binary then lives in your profile and can be started from a
terminal or your app launcher.

### NixOS / Home Manager (flake input)

Add the flake as an input:

```nix
inputs.helium = {
  url = "github:yashsio/helium-browser-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

then put the package in `environment.systemPackages`:

```nix
environment.systemPackages = [
  inputs.helium.packages.${system}.default
];
```

Home Manager works the same way: add the same package to
`home.packages`.

### Overlay

If you would rather have `pkgs.helium` available everywhere:

```nix
{
  nixpkgs.overlays = [ inputs.helium.overlays.default ];
  environment.systemPackages = [ pkgs.helium ];
}
```

## Automatic updates

The workflow in [`.github/workflows/update.yml`](.github/workflows/update.yml)
runs:

- automatically via cron **every 6 hours**, and
- manually from **Actions → update → Run workflow**.

Each run:

1. Executes `./update.sh`, which queries the latest release of
   `imputnet/helium-linux`, downloads both architecture tarballs, computes their
   SRI hashes, and rewrites `sources.json` (version + both hashes).
2. If nothing changed, it stops.
3. Otherwise it runs `nix build .#helium` to **verify the new version builds**
   before committing.
4. Commits `sources.json` as `github-actions[bot]` and pushes to the default
   branch.

Because the build is verified first, a broken release or a wrong hash will never
be committed.

## Contributing

If you find something broken or not working as expected, feel free to open an issue or submit a pull request.

## Credits and license

- **Helium** is created and maintained by
  [imputnet](https://github.com/imputnet) and licensed under **GPL-3.0**. See
  the [Helium repository](https://github.com/imputnet/helium).
- This repository contains **packaging only** and is not affiliated with or
  endorsed by imputnet.
