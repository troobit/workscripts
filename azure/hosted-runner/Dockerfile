# Provenance: imported unchanged from ~/Downloads/tf/az_hostedrunner (self-hosted CI runner image).
FROM alpine:3.15.4
# TODO CLI v2 if required
# Needs much more for alpine
# https://github.com/aws/aws-cli/issues/4685#issuecomment-615872019
#ENV ENV_VARIABLE=value
# Use Alpine apk to install required packages
RUN apk -v --no-cache --update add \
    nodejs \
    npm \
    python3 \
    py3-pip \
    ca-certificates \
    groff \
    less \
    bash \
    make \
    curl \
    wget \
    zip \
    git \
    openssh-client \
    ruby \
    && \
    update-ca-certificates 

# Copy local file requirements.txt to /work/requirements.txt
COPY requirements.txt /work/requirements.txt
COPY github /work/githubtoken
#RUN pip3 install -r /work/requirements.txt
## Sec scan tools
WORKDIR /work
