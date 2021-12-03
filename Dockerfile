FROM gitlab/gitlab-runner:alpine3.14
COPY ./config.toml /etc/gitlab-runner/config.toml
