glab_api = GITLAB_API_URL
img_name = $(glab_api)/USER_OR_GROUP/REPOSITORY_NAME
tag = latest
container = gitlab-runner

# Login to gitlab registery
# It is needed for both pushing and pulling
# the images
# Access tokens or deploy tokens can be used.
# E.g. `make login user=USERNAME pass=PASSWORD`
user = ""
pass = ""
login:
	docker login $(glab_api) -u $(user) -p $(pass)

# Builds the gitlab runner.
#
# `tag` argument can be passed in order
# to add a specific suffix to the image.
# If not given, `latest` will be used by
# default.
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
    	--name $(container) \
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
	docker rm crw-glab-runner
	docker run -d \
    	--restart unless-stopped \
    	--name $(container) \
    	--volume /var/run/docker.sock:/var/run/docker.sock \
    	$(img_name):$(tag)

# Registers a repository runner to the configs.
# Following arguments must be given:
# - `glab_host`: The host address of the gitlab.
#   You can modify this makefile to add default
#   glab_host, which will be used if the argument
#   is not passed specifically.
# - `img`: The docker image to run the jobs on.
#   Default: `docker:stable`
# - `token`: Runner registration token
# - `desc`: Description of the runner

# E.g. `make add-runner token=SOMETOKEN desc="RUNNER DESC"` will run
# `gitlab-runner:latest` image to register the runner with the given
# registration token and description.
glab_host = GITLAB_HOSTNAME
img = docker:stable
token = ""
desc = ""
add-runner:
	@echo $(img)
	docker run \
		-v $(PWD)/config.toml:/etc/gitlab-runner/config.toml \
		--rm $(img_name):$(tag) \
		register -n \
  			--url "$(glab_host)" \
  			--registration-token "$(token)" \
  			--executor docker \
  			--description "$(desc)" \
  			--docker-image "$(img)" \
  			--docker-volumes /var/run/docker.sock:/var/run/docker.sock
