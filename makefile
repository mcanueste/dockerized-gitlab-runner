# Full GitLab GitLab hostname, i.e. https://gitlab.lrz.de
glab_host = 

# Gitlab runner image, i.e. gitlab/gitlab-runner:alpine3.15
runner_img = gitlab/gitlab-runner:alpine3.15

# Docker image to run CI jobs on by default, i.e. docker/stable
job_img = docker:stable

# Gitlab token for adding gitlab runner
token = ""

# Description for the added gitlab runner
desc = ""

run:
	docker run -d \
    	--restart unless-stopped \
    	--name gitlab-runner \
    	--volume /var/run/docker.sock:/var/run/docker.sock \
	--volume $(PWD)/config.toml:/etc/gitlab-runner/config.toml \
    	$(runner_img)

restart:
	docker run -d \
    	--restart unless-stopped \
    	--name gitlab-runner \
    	--volume /var/run/docker.sock:/var/run/docker.sock \
	--volume $(PWD)/config.toml:/etc/gitlab-runner/config.toml \
    	$(runner_img)

add-runner:
	docker run -rm \
		--volume $(PWD)/config.toml:/etc/gitlab-runner/config.toml \
    	        $(runner_img) \
		register -n \
  			--url $(glab_host) \
  			--registration-token "$(token)" \
  			--executor docker \
			--docker-disable-cache \
  			--description "$(desc)" \
  			--docker-image "$(job_img)" \
  			--docker-volumes /var/run/docker.sock:/var/run/docker.sock


# Stops the running gitlab-runner container
stop:
	docker stop gitlab-runner || true

# Cleans the gitlab-runner container if stopped
clean-container:
	docker rm -v gitlab-runner || true

# Cleans the gitlab-runner images if they are not in use
clean-images:
	docker rmi $(runner_img) || true

# Cleans everything related to gitlab-runner if it is not running
clean-all: clean-container clean-images
