# Dockerized Gitlab Runner

## What is Gitlab Runner?
In common CI/CD tools such as Jenkins, you need to create a server that
listens to the changes of the specified repositories, and runs the commands
specified by the user for that repository (E.g. building, testing, and deploying).

Gitlab provides the necessary tools for CI/CD itself, but a server
that listens to the changes is still required. Conveniently, Gitlab also provides
an tool for that, which is called [Gitlab Runner](https://gitlab.com/gitlab-org/gitlab-runner).

We need to [install the gitlab-runner](https://docs.gitlab.com/runner/install/)
to an environment which will act as a server for Gitlab CI/CD, and [register the
runners to the Gitlab](https://docs.gitlab.com/runner/register/) using the [token
provided by the Gitlab](https://docs.gitlab.com/ee/ci/runners/) on the CI/CD
settings of the repositories. After the registration, the **gitlab-runner** is
bound to the repository via the token provided, and it starts to listen the
repository for pipeline requests. (The pipelines are defined in the
[.gitlab-ci.yml](https://docs.gitlab.com/ee/ci/quick_start/#creating-a-gitlab-ciyml-file)
file of the repositories)

When a pipeline request is triggered, **gitlab-runner** spawns a docker container
and pulls the repository to it. Afterwards, it runs whatever command was specified
in the **.gitlab-ci.yml** file for that pipeline.

## What is this repository for?
This repository might be useful if you are running a *self-hosted* **gitlab** instance,
and want to use CI / CD feature.

In order to make it even more convenient to use `gitlab-runner`, we are using the
dockerized version for installing the **gitlab-runner**. We wrap the official
`gilab-runner` container to add our configurations for easy usage. The runner
configurations are kept in the `config.toml` file, which is copied to the gitlab-runner
docker container during build time.

After you register runners, and build the `gitlab-runner`, you can upload the container to
the container registery on gitlab. This way, you can deploy or relocate your
runners easily by pulling the image and running it.

On top of this, with the provided `.gitlab-ci.yml` file, we define a pipeline for building
and uploading the `gitlab-runner` image into a `gitlab registery` as long as the
the runner of the `gitlab-runner` repository is registered with the running `gitlab-running`
instance. Well, that sounds complicated, but in essence, we are automating the build and upload of
the `gitlab-runner` image with the `gitlab-runner` container itself.

## Prerequisites
In order to run the Gitlab Runner, you first need to install docker. Also, in order
to use the `make` commands you need to install `make` (usually comes installed in
many distributions). For `ubuntu`, you can run the following commands:

``` shell
sudo apt update
sudo apt install docker make
```

Afterwards, you just need to clone the repository if you want to change the configurations
or build the runner locally.

``` shell
git clone https://github.com/mcanueste/dockerized-gitlab-runner.git
```

You also need to update the following variables inside the `makefile` according to your
setup:
- `glab_host`: Full GitLab GitLab hostname, i.e. https://gitlab.lrz.de
- `glab_api`: GitLab API URL without `http(s)`, i.e. gitlab.lrz.de
- `namespace`: User or Group namespace on GitLab
- `repo_name`: Repository name under the user or the group, i.e. `gitlab-runner`

## Logging into the gitlab registery
You need to login to the gitlab registry before you can push or pull images
to it. In order to login, just run the following command (assuming you modified
the variables defined in the previous section):
``` shell
make login user=USERNAME_OR_TOKEN_NAME pass=PASSWORD_OR_TOKEN
```

## Building the runner container

In order to build the `gitlab-runner`, you just need to run
``` shell
make build
```

This will build the `gitlab-runner` container with the `latest`
tag. If you want to provide a different tag, run:
```shell
make build tag=TAG
```

## Uploading the runner container

In order to upload the `gitlab-runner` you have built, you just need to run
``` shell
make upload
```

This will upload the `gitlab-runner` container with the `latest`
tag. If you want to provide a different tag, run:
```shell
make upload tag=TAG
```

## Registering a new runner

In order to register a new runner, you just need to run
``` shell
make add-runner token=REGISTRATION_TOKEN desc=RUNNER_DESCRIPTION
```
where the `REGISTRAION_TOKEN` is the *registration token* provided
in `Settings > CI/CD > Runners` of the repository.

The `RUNNER_DESCRIPTION` is the custom description you want to provide
for the runner you are registering.

Optionally, the `img=IMAGE_NAME` can be provided to change the docker
image used for running the jobs in. By default `docker:stable` is used.
This can be useful if you want to use a custom image to run the jobs in.
This custom image can have specific tools/libraries installed inside of it
to make things easier for you.

After running this command a new entry will be added to the `config.toml` file.
You need to commit these changes, and build/upload the `gitlab-runner` container
again to make sure the changes persist.

## Running the gitlab-runner
You can run the `gitlab-runner` by cloning the repository and using the following command:
``` shell
make run
```

If you want to run a different version of the runner, you can pass
`tag=TAG` argument to the `make` command, e.g. `make run tag=latest`.

## Restart the gitlab-runner
You can restart the `gitlab-runner` using the following command:
``` shell
make restart
```

If you want to run a different version of the runner, you can pass
`tag=TAG` argument to the `make` command, e.g. `make restart tag=latest`.

If you have added a new commit to the `gitlab-runner` repository and there
is a new image of it on the `gitlab registery` due to the defined `CI/CD`
pipeline, you probably want to switch to that image as well. For that,
you have to first pull the new image (with tag if you have defined),
using the `make pull` command. Afterwards you can run `make restart`
normally.

## Relocating the runners
When we start runners, Gitlab registers the runners on that machine and binds them
as the servers for running pipelines. If the runners are run on multiple machines
Gitlab will recognize the last location the runner was run as the actual location
and will disregard the others. This means that in order to relocate the runners,
we just need to run the `gitlab-runner` container on the machine we want, and it
will be updated as the actual runner.

## CI/CD of `gitlab-runner` itself
Currently, we have a single build and upload pipeline for the `gitlab-runner` defined
in the `.gitlab-ci.yml` file. Currently it only uses the `latest` tag for the image,
however it can easily be extended to cover other tags or use cases. Additional information
can be found on the [GitLab Documentation](https://docs.gitlab.com/ee/ci/quick_start/#creating-a-gitlab-ciyml-file).

However, for this pipeline to work, a variable must be defined on `Settings > CI/CD > Variables`
page with `GLAB_API_TOKEN` as key, storing the `access token` value, which can be created under
`Settings > Access Tokens`. This is needed so the `gitlab-runner` can fetch the repository and run
the pipeline.

## Additional Sources
- [Advanced runner configuration documentation](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)
