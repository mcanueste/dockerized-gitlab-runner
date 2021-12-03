# Dockerized Gitlab Runner

## What is Gitlab Runner?
In common CI/CD tools such as Jenkins, you need to create a server that
listens to the changes of the specified repositories, and runs the commands
specified by the user for that repository (E.g. building, testing, and deploying).

Gitlab provides the necessary tools for CI/CD itself, but a server
that listens to the changes is still required. Conveniently, Gitlab also provides
an open source tool for that, which is called [Gitlab Runner](https://gitlab.com/gitlab-org/gitlab-runner).

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
In order to make it even more convenient to use `gitlab-runner`, we are using the
dockerized version for installing the **gitlab-runner**. We wrap the official
`gilab-runner` container to add our configurations for easy usage. The runner
configurations are kept in the `config.toml` file, which is copied to the gitlab-runner
docker container during build time.

After you register runners, and build the `gitlab-runner`, you can upload the container to
the container registery on gitlab. This way, you can deploy or relocate your
runners easily by pulling the image and running it.

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
git clone https://gitlab.lrz.de/commonroadwebdev/gitlab-runner.git
```

You also need to update the following variables inside the `makefile` according to your
setup:
- `glab_api`: The gitlab api url (e.g. gitlab.lrz.de:5005).
- `img_name`: The image name of the `gitlab-runner`. This variable already prepends the
    `glab_api` variable to the name. You just need to provide the *user or group name*
    and the *repository name*.
- `glab_host`: The gitlab host to be used when registering a runner.
- *(Optional)* `container`: The default container name of the `gitlab-runner`.

## Logging into the gitlab registery
You need to login to the gitlab registery before you can push or pull images
to it. In order to login, just run the following command (assuming you modified
the variables defined in the previous section):
``` shell
make login user=USERNAME_OR_TOKEN_NAME pass=PASSWORD_OR_TOKEN
```

## Running the gitlab-runner
There are two ways to run the `gitlab-runner`:
1. By cloning the repository and using `docker-compose`, or
2. Pulling the image directly without downloading the repository

In order to run the `gitlab-runner` by cloning the repository:

``` shell
git clone https://gitlab.lrz.de/commonroadwebdev/gitlab-runner.git
cd gitlab-runner
make run
```
If you want to run a different version of the runner, you can pass
`tag=TAG` argument to the `make` command, e.g. `make run tag=latest`.

In order to run the `gitlab-runner` by pulling the image directly.
``` shell
docker run -d \
    --restart unless-stopped \
    --name CONTAINER_NAME \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    IMAGE_NAME:TAG
```
where `CONTAINER_NAME` is the name you want to assign to the container,
`IMAGE_NAME` is the full name of the `gilab-runner` image (e.g.
`gitlab.com:5005/somegroup/somerepo`), and `TAG` is the tag of
the image you want to use.

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

**Note-1:** You can also automate the `gitlab-runner` build/upload processes with
the `gitlab-runner` itself. So meta, eh? :D.

**Note-2:** If you want the new runner to be activated immediately, you also need
to pull the changes on the machine the runners are serving and restart the containers.
This can be done by running `make pull` and `make restart` command if you have cloned
the repository (you can also specify `tag`). Otherwise you need to run:
``` shell
docker pull IMAGE_NAME:TAG
docker rm CONTAINER_NAME
docker run -d \
    --restart unless-stopped \
    --name CONTAINER_NAME \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    IMAGE_NAME:TAG
```

## Relocating the runners
When we start runners, Gitlab registers the runners on that machine and binds them
as the servers for running pipelines. If the runners are run on multiple machines
Gitlab will recognize the last location the runner was run as the actual location
and will disregard the others. This means that in order to relocate the runners,
we just need to run the `gitlab-runner` container on the machine we want, and it
will be updated as the actual runner.

## Additional Sources
- [Advanced runner configuration documentation](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)
