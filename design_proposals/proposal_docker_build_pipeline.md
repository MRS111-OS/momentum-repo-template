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

## Non goals
- Non ROS build systems are not supported for the POC, can be done as the next step.
- Multi-arch builds 
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
```

Note: For cyborg_ros2, this is entirely just a moving operation, and not a rewrite as it already separates these inputs into the named files read by relative path (`ci/custom_packages.txt`, `docker/runtime_source_packages.txt`, etc) rather than hardcoding them in the Dockerfile, that is one of the reasons why this generalizes easily. 

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

_(to fill in)_

### Build context: how the shared Dockerfile sees product source

_(to fill in)_

#### Script Responsibilities
- `bin/build.sh` : the only entrypoint anyone runs. Takes --product, and either --ref (clone path) or --local-path (dev path), plus --env. Its job is purely sequencing: call clone.sh to get a checked-out product tree, call identity.sh to compute source and write docker-build-info.yaml into the build context, invoke docker buildx build against the product's .momentum-build/ contract, then call registry.sh for test/push/pull as asked. It holds no logic of its own beyond orchestration. Everything else is delegated so each piece is testable alone.


lib/clone.sh : given {product repo, checkout}, resolves the checkout to a commit, does a shallow clone, and hands back a filesystem path plus the resolved sha. This is the only place "what does main mean right now" gets answered, resolved once, then treated as fixed for the rest of the run. For --local-path, it skips the clone and instead checks whether the tree has uncommitted changes, since dev builds are the one path allowed to have them.

lib/identity.sh : pure computation, no side effects on the registry. Reads the resolved commit and checkout value from clone.sh, and the product's .momentum-build/product.env, and writes docker-build-info.yaml into the build context so the Dockerfile can copy it into the image. Also derives the tag names (the immutable version tag and the moving env tag) from the same inputs, so build.sh and registry.sh use the same tag string without the naming logic living in two places.

Shape of docker-build-info.yaml:

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
image_tag: v0.3.1-2-g9f2a1c3
built_at: 2026-09-08T19:40:00Z
```

lib/registry.sh : thin wrapper around docker login/push/pull, plus the tag rules: refuses to push a dev image, refuses to push a build that has uncommitted changes. The script itself is complete and ready to use, it just has nothing to point at yet. It stays dormant until an actual registry is live. dev and test builds don't need it, those images never leave the machine that built them.

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

_(to fill in — --checkout accepting a branch, tag, or commit interchangeably; whether login/version are in scope alongside build/test/push/pull)_

### Tag scheme

_(to fill in)_

### Test environment

_(to fill in — what --env test produces differently from prod)_

### Runtime configuration

Some values are known at build time (which packages, which commit) and go into the image. Some values are only known once an image is running on a specific robot (which CycloneDDS profile, which maps, which ROS_DOMAIN_ID), and those must never go into the image. Baking a per-robot value into the image would mean building a separate image per robot, which defeats the point of one image being deployable anywhere.

These per-robot values come in two shapes: scalars and files.

**Scalars** are single values, passed as environment variables. They come from a `.env` file that lives on the robot itself, next to the compose file, and is never checked into any repo. Compose reads it automatically and substitutes it into the YAML. Shape:

```
IMAGE=registry.example.com/cyborg/cyborg_ros2:v0.1.0-3-gabc1234
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

_(to fill in)_