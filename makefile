# Full GitLab GitLab hostname, i.e. https://gitlab.lrz.de
glab_host = GITLAB_HOSTNAME

# GitLab API URL without `http(s)`, i.e. gitlab.lrz.de
glab_api = GITLAB_API_URL

# User or Group namespace on GitLab
namespace = USER_OR_GROUP_NAMESPACE

# Repository name under the user or the group, i.e. `gitlab-runner`
repo_name = REPO_NAME

# Full Docker image name
img_name = $(glab_api)/$(namespace)/$(repo_name)

# Default image tag
tag = latest

# User to be used for logging into the GitLab API
user = ""

# Password to be used for logging into the GitLab API
pass = ""

# Login to gitlab registery
# It is needed for both pushing and pulling
# the images
# Access tokens or deploy tokens can be used.
login:
	docker login $(glab_api) -u $(user) -p $(pass)

# Builds the gitlab runner.
#
# `tag` argument can be passed in order
# to add a specific suffix to the image
# (used for versioning). If not given,
# `latest` will be used by default.
#
# E.g. `make build tag=1` will create
# `gitlab-runner:latest` image.
build:
	docker build -t $(img_name):$(tag) .

# Uploads the gitlab-runner.
#
# `tag` argument can be passed in order
# to add a specific suffix to the image
# (used for versioning). If not given,
# `latest` will be used by default.
#
# E.g. `make upload tag=1` will upload
# `gitlab-runner:1` image.
upload:
	docker push $(img_name):$(tag)

# Pulls the gitlab-runner.
#
# `tag` argument can be passed in order
# to add a specific suffix to the image
# (used for versioning). If not given,
# `latest` will be used by default.
#
# E.g. `make pull tag=1` will pull
# `gitlab-runner:1` image.
pull:
	docker pull $(img_name):$(tag)

# Runs the gitlab-runner.
#
# `tag` argument can be passed in order
# to add a specific suffix to the image
# (used for versioning). If not given,
# `latest` will be used by default.
#
# E.g. `make run tag=1` will run
# `gitlab-runner:1` image.
run:
	docker run -d \
    	--restart unless-stopped \
    	--name glab-runner \
    	--volume /var/run/docker.sock:/var/run/docker.sock \
    	$(img_name):$(tag)

# Restarts the gitlab-runner.
#
# `tag` argument can be passed in order
# to add a specific suffix to the image
# (used for versioning). If not given,
# `latest` will be used by default.
#
# E.g. `make restart tag=1` will restart
# `gitlab-runner:1` image.
restart:
	docker rm glab-runner
	docker run -d \
    	--restart unless-stopped \
    	--name glab-runner \
    	--volume /var/run/docker.sock:/var/run/docker.sock \
    	$(img_name):$(tag)

# Registers a repository runner to the configs.
# Following arguments must be given:
# - token: Runner registration token
# - desc: Description of the runner
# - img: The docker image to run the jobs on.
#   Default: `docker:stable`
#
# E.g. `make add-runner token=SOMETOKEN desc="RUNNER DESC"` will run
# `gitlab-runner:latest` image to register the runner with the given
# registration token and description.
token = ""
desc = ""
img = docker:stable
add-runner:
	@echo $(img)
	docker run \
		-v $(PWD)/config.toml:/etc/gitlab-runner/config.toml \
		--rm $(img_name):$(tag) \
		register -n \
  			--url $(glab_host) \
  			--registration-token "$(token)" \
  			--executor docker \
			--docker-disable-cache \
  			--description "$(desc)" \
  			--docker-image "$(img)" \
  			--docker-volumes /var/run/docker.sock:/var/run/docker.sock


# Stops the running gitlab-runner container
stop:
	docker stop glab-runner || true

# Cleans the gitlab-runner container if stopped
clean-container:
	docker rm -v glab-runner || true

# Cleans the gitlab-runner images if they are not in use
clean-images:
	docker rmi $(img_name):$(tag) || true
	docker rmi gitlab/gitlab-runner:alpine3.14 || true

# Cleans everything related to gitlab-runner if it is not running
clean-all: clean-container clean-images
