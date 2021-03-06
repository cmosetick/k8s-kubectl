# Forked from: https://github.com/lachie83/k8s-kubectl

FROM alpine

ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/cmosetick/k8s-kubectl" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile"

ENV KUBE_LATEST_VERSION="v1.17.2"

RUN \
apk add --no-cache --update ca-certificates && \
apk add --no-cache --update -t deps curl && \
curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl

# sops build
# For more info - https://github.com/mozilla/sops
# update sops build process below
FROM golang:1.13
RUN \
go get -u go.mozilla.org/sops/v3 && \
cd $GOPATH/src/go.mozilla.org/sops/v3 && \
make install && \
# remove sops even though go install will overwrite.
rm -rf /go/bin/sops && \
CGO_ENABLED=0 GOOS=linux go install -a -ldflags '-extldflags "-static"' go.mozilla.org/sops/v3/cmd/sops

# kubectl and sops installation into final image
FROM alpine
WORKDIR /root
COPY --from=0 /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=1 /go/bin/sops /usr/local/bin/sops
RUN \
apk add --no-cache --update ca-certificates && \
chmod +x /usr/local/bin/kubectl && \
chmod +x /usr/local/bin/sops && \
mkdir /root/.kube && \
mkdir /root/.aws && \
touch /root/.aws/credentials && \
touch /root/.aws/config

WORKDIR /usr/local/bin
CMD ["/usr/local/bin/kubectl"]
