# Framewing

## Local development builds

- The local build is named **Framewing-dev**: `./build.sh` produces `build/Framewing-dev.app` with its own name and bundle identifier `io.github.ruslan-palahin.framewing.dev`. It must never share a bundle identifier with another copy of Framewing (release: `io.github.ruslan-palahin.framewing`), otherwise Launchpad, Spotlight, the Dock and Finder's Open With may launch a stale copy.
- Replace the installed copy right after every local build:

  ```sh
  rm -rf /Applications/Framewing-dev.app && cp -R build/Framewing-dev.app /Applications/
  ```

- If Framewing-dev is running, it keeps the old build until the owner relaunches it; do not quit it yourself.
