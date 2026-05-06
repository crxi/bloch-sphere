# Bloch sphere — quantum gate tutorial

A single-file interactive Bloch sphere for learning what one-qubit gates
*do*, geometrically. Drag to rotate the camera; click a gate to apply it
and watch the state's Bloch vector rotate around the gate's axis.

**Live: https://crxi.github.io/bloch-sphere/**

## What's in here

- **Single-qubit gates**: H, X, Y, Z, S, S†, T, T†. Animated rotation
  around the gate's axis with the rotation plane and axis line shown
  during the animation.
- **Continuous Rx/Ry/Rz sliders**: each slider shows the Euler-angle
  decomposition of the current state from |0⟩, and dragging applies an
  incremental rotation. Rotations around an axis through the state's
  current pole leave the state put (e.g. dragging Rx from |+⟩ doesn't
  move the arrow; the slider snaps back on release).
- **Presets**: |0⟩ |+⟩ |+i⟩ on top, |1⟩ |−⟩ |−i⟩ below — antipodes line
  up, columns are the Z / X / Y axes.
- **Light/dark theme**, persisted in `localStorage`. Sphere wireframe,
  axis labels, arrow, and rotation indicators all re-colour.
- **Resizable rails**: drag the thin handles between the side rails and
  the canvas; widths persist.
- **Collapsible/reorderable panels** in both rails: each panel header has
  ▲▼▾. Order persists per-rail.
- **Mobile**: tabbed bottom-sheet (GATES / STATE / MORE) below 1024px.
  The sphere stays at the top, controls below.

No build step. No runtime dependencies beyond Three.js (loaded from
jsDelivr). The whole app is one HTML file.

## Files

| File | What it is |
|---|---|
| `bloch_sphere.html` | The app. |
| `index.html` | Tiny meta-refresh redirect to `bloch_sphere.html` so the bare GH-Pages URL works. |
| `setup_web_test.sh` | Local dev helper — spins up an ephemeral Cloudflare tunnel so you can test edits on your phone. Live edits via symlink + no-cache headers. |
| `deploy_gh_pages.sh` | Pushes the repo to GitHub and enables Pages from `main` / root. Uses the [`gh`](https://cli.github.com) CLI. |

### Local mobile testing

```bash
./setup_web_test.sh
# prints a https://...trycloudflare.com URL — open on your phone.
# Ctrl+C to stop. HTML edits are picked up live (just hard-refresh).
```

### Deploying

```bash
./deploy_gh_pages.sh           # default: public repo "bloch-sphere"
./deploy_gh_pages.sh my-name private
```

Re-runs are idempotent. After the first deploy, normal updates are just
`git push`.

## Known gaps

- The slider Euler decomposition is canonical; for arbitrary mixed or
  non-cardinal states the inferred angles may not match what a textbook
  would write.
- No tests in this repo. There's a small suite at
  `/tmp/bloch-test/test-quantum-logic.mjs` (Playwright) that I run
  during development; it's not committed because it's a personal scratch
  script.

## Credit

Built mostly by AI (heavy lifting on math, Three.js scene plumbing,
layout iteration) with a human (crxi) driving the requirements and UX
decisions. Commit author reflects that order.
