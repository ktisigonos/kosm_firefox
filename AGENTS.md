# AGENTS.md

Instructions for AI coding agents working on `kosm_firefox`, a kosm package. Kosm's own rules apply in full: read `../kosm/AGENTS.md` and the files it points to. This file holds only what is specific to this package.

## npm never runs on the host

**Never run `npm`, `npx`, `node` or any other JavaScript package tool directly on the human's system.** Run them only inside a container: podman if it is installed, else docker. For example, to fetch a new Dark Reader into a scratch directory:

```sh
podman run --rm -v "$PWD:/work:Z" -w /work docker.io/library/node:22-alpine npm pack darkreader@<version> --ignore-scripts
```

Then unpack the tarball outside the container and copy only what the extension needs. Nothing installs packages into this repository.

## The extension

- `extension/` is Kosm, the extension that can be signed; `extension/live/` holds only what Kosm Live adds (its manifest, the experiment's `schema.json` and `api.js`). Both share every other file, so never copy code between them. The live manifest must stay Kosm's but for its name, id, description and `experiment_apis` (a test checks this).
- `extension/darkreader.js` and `extension/darkreader-LICENSE` are the MIT npm package `darkreader`, vendored unchanged; its version is in `README.md`. Updating it is a dependency change (kosm's hard rule 5).
- Raise the version in both manifests whenever a file of the extension changes, so browsers reload the unpacked Kosm Live.
- Test the extension only in a scratch browser profile with `HOME` pointed at a scratch directory, never in the human's profiles or `~/.mozilla`.
