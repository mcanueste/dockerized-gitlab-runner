FROM gitlab/gitlab-runner:alpine3.15
COPY ./config.toml /etc/gitlab-runner/config.toml
