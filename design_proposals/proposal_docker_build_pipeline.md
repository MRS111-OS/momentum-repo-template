# Design Proposal for Setting up a Docker Build Pipeline for Momentum Robotics

**Date** - 8th September 2026

**Author** - Akshay


## Problem 

Currently, Momentum Robotics relies on either building stand-alone docker images for a stack or deploys the whole stack onto the robot. There is no central build pipeline infrastructure present to support building docker images for a stack that can be built for any product (pixel, cyborg, agv, etc). 

Due to the absence of such a central repository that can handle such functionalities, team has to depend on memory, communication and basic book-keeping to understand what code should be on what product. 

There is a lack of definitiveness when it comes to pointing at what code is running on a robot until someone gets inside the robot and finds the branch or commit of a repository. 

## Proposed Solution

Development of a centralised repository which handles 
- the setting up of the env (test, prod, dev)
- getting the right code (repo, branch, commit) into the env
- the core building tools to produce the image based on few commands 
- create artifacts such as a docker-build-info.yaml that reflects what code is present in the docker image to remove any ambiguity


## Goals

- One repo that builds the image for any ROS2/colcon product, for any enviroment, from config + shell scripts, no new templating language
- The image's origin or source is not ambiguous
    - docker-build-info.yaml (artifact) will contain information such as 
        - which repo is used 
        - which packages are present
        - which commit is picked up 
- Docker compose files share a common base template, only the genuinely specific settings such as product configs, product env variables are override.
- Lightweight
- Version controlled so any new feature or product is added, it should reflect the repo's ability to build such an image.
- Multi-arch (amd64/arm64) images from the POC, so pixel_ros2's Raspberry Pi target builds without a follow-up phase.

## Non goals
- Non ROS build systems are not supported for the POC, can be done as the next step.
- Retiring cyborg_ros2/docker/image.sh. The POC proves a parity against such image and removing and moving to the centralised build pipeline is a separate discussion. 


## Options considered

| Option | Upside | Cost / risk |
|---|---|---|
| A. Pipeline clones the product repo at a pinned checkout (proposed) | Getting the right code into the env is true by how the build works, not by a check that can be skipped or missed. One repo produces every image | Bigger change than the alternatives. Every product repo needs the .momentum-build contract before it can be built this way. Build machines need to be able to clone product repos, not just build in a tree that's already checked out |
| B. Keep building in place, sync a shared template into each product's own docker/ folder | Smaller change, each repo keeps building the way cyborg_ros2 does today | Doesn't remove the ambiguity this proposal exists to fix, a repo can still build a tree with uncommitted changes in it. Keeping the synced template up to date in every repo is its own unsolved problem |
| C. Do nothing, each repo keeps building its own way | No work now | The problem in the Problem section stays true, no central place to say what's on a product, and no way to know what's running on a robot except getting inside it and checking |

Decision: A.

Why: it's the only option where "the right code, at the right commit, is in the image" is true because of how the build works, not because something remembered to check for it. Most of what A needs already exists in cyborg_ros2's docker/ setup today (the staged Dockerfile, the tag scheme, the package list files kept as separate named files), so this is mostly extracting and generalizing what's already there, not new design.

## Implementation details 

### Product specific configuration and where it should be defined

Product specific configuration should be defined in the product repository. Maintaining the product specifications is not the responsibility of the pipeline repo. 

If they lived in the repository instead, image information of "built at commit X" would stop being a complete and accurate answer (as the package list used might be from a different pipeline repo state entirely, unrelated to what commit X of the product repo actually declares). Pinning the source reference only guarantees reproducibility if everything the build depends on is cloned at that same reference. 

So the pipeline repo should define a small, versioned contract: a fixed set of paths, it expects to find in any product repo, it's asked to build, cloned at the requested reference, e.g.:

```
<product-repo>/.momentum-build/
├── product.env        # IMAGE_NAME, ROS_DISTRO, WS_INSTALL, packages to build
├── packages.txt        # first-party packages (today's ci/custom_packages.txt in cyborg_ros2)
├── runtime_apt.txt
├── runtime_system.txt
└── compose/
    ├── dev.yml
    ├── test.yml
    └── prod.yml         # layered on the pipeline repo's templates/compose/base.yml
```

Shape of product.env:

```
IMAGE_NAME=cyborg_ros2
ROS_DISTRO=humble
WS_INSTALL=/opt/cyborg
SUBMODULES=false
```

Note: For cyborg_ros2, this is entirely just a moving operation, and not a rewrite as it already separates these inputs into the named files read by relative path (`ci/custom_packages.txt`, `docker/runtime_source_packages.txt`, etc) rather than hardcoding them in the Dockerfile, that is one of the reasons why this generalizes easily. 

Whether a product's checkout needs submodules is part of this same contract, not something the pipeline repo decides on its own. `clone.sh` reads `SUBMODULES` from `product.env` after the initial clone and, if set, runs `git submodule update --init --recursive` before handing the tree back. This keeps "getting the right code into the env" true for products that use submodules without the pipeline repo having to know which ones do.

### Proposed Repo Layout (`momentum-build-pipeline`)

```
momentum-build/
├── bin/
│   ├── build.sh          # clone -> resolve identity -> build -> tag -> (test|push|pull)
│   └── lib/
│       ├── clone.sh       # pin by ref, shallow clone, resolve to a commit sha
│       ├── identity.sh    # compute + embed sources (below)
│       └── registry.sh    # login/push/pull : thin wrapper, same tag scheme as done in cyborg_ros2
├── templates/
│   ├── ros2/Dockerfile     # cyborg_ros2's 4-stage Dockerfile, generalized to read
│   │                       # .momentum-build/* instead of docker/*
│   └── compose/base.yml    # shared service defaults: logging driver, restart
│                            # policy, stop_signal : the parts every product shares
└── registry.env.example
```

### Dockerfile template

Four stages, the same ones cyborg_ros2 uses today: `manifests` (extracts package.xml files and the .momentum-build config so dependency install can be cached against them), `builder` (compiles the workspace), `runtime` (ros-base plus the apt packages the product needs, plus the built install/ copied out of builder, nothing else), and `test` (builder plus linters, for CI and desk use, never shipped). Moving to the pipeline repo only changes what each stage reads its inputs from, docker/*.txt becomes <clone>/.momentum-build/*.txt, the four-stage structure itself doesn't change.

### Build context: how the shared Dockerfile sees product source

The Dockerfile lives in the pipeline repo. The product's source lives wherever clone.sh checked it out, a separate directory. `docker buildx build` takes the pipeline repo as the default build context (the Dockerfile and its scripts) and the cloned product directory as a second, named context: `--build-context product=<clone-path>`. Wherever the Dockerfile needs the product's source or its .momentum-build/ files, it copies from that named context (`COPY --from=product ...`) instead of the default one. That's what lets one shared Dockerfile build a product it doesn't itself contain.

### Multi-arch builds

`--platform` is a `build.sh` flag, passed straight through to `docker buildx build`. `product.env` sets the default for a product (`linux/amd64` for cyborg_ros2, `linux/amd64,linux/arm64` for pixel_ros2), and `--platform` on the command line overrides it for a one-off build. Buildx cross-builds `linux/arm64` on an `amd64` runner through QEMU emulation once the `binfmt` handler is registered on the build machine, so the POC doesn't need a separate ARM build host. A multi-platform build produces one manifest list per tag, so a robot's `docker pull` resolves to its own architecture automatically and the tag scheme is unaffected. `docker-build-info.yaml` gains a `platforms` field listing what was built.

#### Script Responsibilities
- `bin/build.sh` : the only entrypoint anyone runs. Takes --product, and either --ref (clone path) or --local-path (dev path), plus --env. Its job is purely sequencing: call clone.sh to get a checked-out product tree, call identity.sh to compute source and write docker-build-info.yaml into the build context, invoke docker buildx build against the product's .momentum-build/ contract, then call registry.sh for test/push/pull as asked. It holds no logic of its own beyond orchestration. Everything else is delegated so each piece is testable alone.


- `lib/clone.sh` : given {product repo, checkout}, resolves the checkout to a commit, does a shallow clone, and hands back a filesystem path plus the resolved sha. This is the only place "what does main mean right now" gets answered, resolved once, then treated as fixed for the rest of the run. For --local-path, it skips the clone and instead checks whether the tree has uncommitted changes, since dev builds are the one path allowed to have them.

- `lib/identity.sh` : pure computation, no side effects on the registry. Reads the resolved commit and checkout value from clone.sh, and the product's .momentum-build/product.env, and writes docker-build-info.yaml into the build context so the Dockerfile can copy it into the image. Also derives the tag name (`<env>-<product>-<feature-or-date>`, see Tag scheme below) from the same inputs, so build.sh and registry.sh use the same tag string without the naming logic living in two places.

- `lib/registry.sh` : thin wrapper around docker login/push/pull, plus the tag rules: refuses to push a dev image, refuses to push a build that has uncommitted changes. The script itself is complete and ready to use, it just has nothing to point at yet. It stays dormant until an actual registry is live. dev and test builds don't need it, those images never leave the machine that built them.

#### Shape of docker-build-info.yaml:

```yaml
product: cyborg_ros2
repo: momentum-robotics/cyborg_ros2
requested_checkout: fix/issue-13
resolved_commit: 9f2a1c3
has_uncommitted_changes: false   # only ever true on a dev build
packages:
  - laser_merger2
  - cyborg_bringup
env: test
image_tag: test-cyborg_ros2-fix_issue_13
built_at: 2026-09-08T19:40:00Z
```


**Why this needs an actual registry, not a server or a cloud drive standing in for one**

docker push and docker pull speak a specific protocol, the Docker Registry API, not generic file transfer. A server and a cloud drive account are storage, not that API, so neither is a drop-in replacement without something running on it that actually implements the registry protocol.

If the plan instead is to docker save an image to a file, move that file to a server or a synced cloud folder, then docker load it back on the other end, that drops everything a registry is actually for:

- Tags and digests are gone. The folder has to invent its own way of saying which file is which version, which is exactly the ambiguity this proposal exists to remove
- Every pull is the full image, there is no layer reuse. cyborg_ros2's image is about 3.1 GB, so a robot pulling the whole thing for a one-line code change is the opposite of the faster dev and test cycles this is for
- Nothing enforces atomicity. A sync interrupted partway leaves a half-written file that docker load either fails on or, worse, loads
- Access is file permissions or share links, not scoped read-only tokens, so there is no way to give a robot pull-only access the way a registry token does
- Cleanup is manual. Nothing prunes an old version once it is no longer needed, so the folder only grows

None of this is a reason to avoid using the server or the cloud account, it is a reason not to use them as if they were a registry. If a registry is not available yet, the fix is running registry software on the server that is already there. That is an actual registry, and registry.sh already targets exactly that, it is just not live yet.


Usage:

```
./bin/build.sh --product cyborg_ros2 --checkout v0.3.1 --env prod
./bin/build.sh --product cyborg_ros2 --checkout fix/issue-13 --env test
./bin/build.sh --product cyborg_ros2 --checkout 9f2a1c3 --env test
./bin/build.sh --product cyborg_ros2 --local-path ../cyborg_ros2 --env dev
```

### CLI commands in scope

`build.sh` supports six commands: `build`, `test`, `push`, `pull`, `login`, and `version` — matching image.sh's existing surface so nothing is lost in the generalization.

`--checkout` accepts a branch name, a tag, or a commit sha interchangeably, whatever `git checkout` would accept. It gets resolved to a commit once, by clone.sh, and that resolved commit, not the string that was passed, is what ends up in docker-build-info.yaml.

`login` is registry login, not git. It stores a credential the same way `docker login` always has, interactively, so nothing lands in shell history or a script argument. It has nothing to do with the credential clone.sh uses to check out the product repo, that's a separate concern this proposal doesn't specify.

`version` prints the tag a build would use without building anything, for checking what a given {product, checkout, env} would resolve to before spending the time to build it.

### Tag scheme

One tag per image: `<env>-<product>-<feature-or-date>`.

The last part depends on what's being built. Building off a feature or fix branch uses a slug of the branch name, for example checkout `fix/issue-13` on `cyborg_ros2` for `test` gives:

```
test-cyborg_ros2-fix_issue_13
```

Building off `main` or a release uses the build date instead, since there's no single feature name to point to:

```
prod-cyborg_ros2-20260908
```

Pushing again under the same tag overwrites what it points to — rebuilding the same feature branch after a new commit moves the tag forward, the same way a branch itself moves forward. The tag is a convenient way to address an image when pulling, it is not the record of what's actually in it. That record is `docker-build-info.yaml`, already defined above: `resolved_commit` is fixed the moment an image is built and never changes no matter how many times the tag gets reused. Anyone who needs to know exactly what a running image is should read that file, not infer it from the tag.

### Test environment

`--env test` builds the Dockerfile's `test` stage instead of `runtime`, builder plus linters, and runs `colcon test` after the build. Lint is advisory (`ci/lint.sh` always exits 0 today, matching cyborg_ros2), colcon test does gate the build (`--return-code-on-test-failure`, so a failing test fails the build).

One limitation carries over rather than gets fixed here: cyborg_ros2 currently has no tests in any of its packages, so `colcon test` finds nothing to run and reports success. A green test build today proves the image builds and lints cleanly, nothing more. Writing real tests is product-repo work, tracked separately, not something the pipeline repo can do on the product's behalf.

Test images are never pushed.

### Runtime configuration

Some values are known at build time (which packages, which commit) and go into the image. Some values are only known once an image is running on a specific robot (which CycloneDDS profile, which maps, which ROS_DOMAIN_ID), and those must never go into the image. Baking a per-robot value into the image would mean building a separate image per robot, which defeats the point of one image being deployable anywhere.

These per-robot values come in two shapes: scalars and files.

**Scalars** are single values, passed as environment variables. They come from a `.env` file that lives on the robot itself, next to the compose file, and is never checked into any repo. Compose reads it automatically and substitutes it into the YAML. Shape:

```
IMAGE=registry.example.com/cyborg_ros2:prod-cyborg_ros2-20260908
ROS_DOMAIN_ID=0
```

used in the compose file as `${IMAGE:?set IMAGE}` and `${ROS_DOMAIN_ID:-0}`. Every robot has its own `.env`, so the same image runs on every robot with each one substituting its own values in.

**Files** are anything too big to be one value, like a CycloneDDS profile or a map. The image ships a default at a fixed path, and the robot's compose file bind-mounts the real file over that path:

```yaml
volumes:
  - /home/cyborg/cyclonedds.xml:/config/cyclonedds.xml:ro
  - /home/cyborg/site:/site:ro
```

The container always reads `/config/cyclonedds.xml`. Whether that's the image's own default or the robot's real profile depends only on what's mounted when the container starts, nothing in the image needs to know which robot it's on.

### Why templates/compose has its own base file

A product's compose file has two kinds of settings mixed together: things every product needs (restart policy, logging driver, stop signal) and things only that product needs (which devices, which volumes, which network mode). Goals already state compose files should share a common base template and only override the genuinely product-specific settings, this is what implements that.

`templates/compose/base.yml` holds only the first kind:

```yaml
services:
  bringup:
    restart: unless-stopped
    logging:
      driver: journald
      options:
        tag: ${IMAGE_NAME}
```

and the product's own compose file holds only what's specific to it:

```yaml
services:
  bringup:
    image: ${IMAGE:?set IMAGE}
    network_mode: host
    devices:
      - /dev/motor_driver:/dev/motor_driver
    volumes:
      - /home/cyborg/cyclonedds.xml:/config/cyclonedds.xml:ro
    environment:
      - ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
```

run together as `docker compose -f templates/compose/base.yml -f <product>/.momentum-build/compose/prod.yml up -d`. A change to something every product shares, like the logging driver, happens once in base.yml instead of once per product.

## Rollout

Four stages, each gated on the previous one passing:

1. **Design proposal acceptance** — 2 days.
2. **Repo creation** — 2 days. Scaffold `momentum-build`: `bin/build.sh` and `lib/*.sh`, `templates/ros2/Dockerfile` and `templates/compose/base.yml`, `registry.env.example`. Most of this is extraction from cyborg_ros2's existing docker/ setup, not new code.
3. **POC run on cyborg_ros2** — 1 week. Add the `.momentum-build/` contract to cyborg_ros2, wire build.sh end to end, prove the pipeline builds, tags, and produces a correct docker-build-info.yaml. Proving push/pull as part of parity needs a live registry, per the registry note above, this stage is blocked on that being ready rather than on anything in this stage's own scope.
4. **Test run on pixel_ros2** — 1 week. Same bar as stage 3, plus proving the `linux/arm64` build actually boots on a Raspberry Pi, not just that it builds. pixel_ros2 has no .momentum-build/ contract yet, so this is where one gets written for the first time, confirming the pipeline generalizes rather than only working against cyborg_ros2.

**POC complete** once stage 4 passes. Retiring image.sh, scaffolding momentum-repo-template, and any product beyond these two are separate decisions, not part of this rollout.