FROM openshift/origin-release:golang-1.13 AS builder
ENV SOURCE_GIT_COMMIT=2808c2cbb256460d929491f33ec5858ceebb211c SOURCE_DATE_EPOCH=1574358517 BUILD_VERSION=v4.4.0 SOURCE_GIT_URL=https://github.com/openshift/ovn-kubernetes SOURCE_GIT_TAG=2808c2cb BUILD_RELEASE=201912202230

WORKDIR /go-controller
COPY go-controller/ .

# build the binaries
RUN CGO_ENABLED=0 make

FROM openshift/origin-cli AS cli
ENV SOURCE_GIT_COMMIT=2808c2cbb256460d929491f33ec5858ceebb211c SOURCE_DATE_EPOCH=1574358517 BUILD_VERSION=v4.4.0 SOURCE_GIT_URL=https://github.com/openshift/ovn-kubernetes SOURCE_GIT_TAG=2808c2cb BUILD_RELEASE=201912202230

FROM openshift/origin-base
ENV SOURCE_GIT_COMMIT=2808c2cbb256460d929491f33ec5858ceebb211c SOURCE_DATE_EPOCH=1574358517 BUILD_VERSION=v4.4.0 SOURCE_GIT_URL=https://github.com/openshift/ovn-kubernetes SOURCE_GIT_TAG=2808c2cb BUILD_RELEASE=201912202230

USER root

ENV PYTHONDONTWRITEBYTECODE yes

# install needed rpms - openvswitch must be 2.10.4 or higher
# install selinux-policy first to avoid a race

RUN mkdir -p /var/run/openvswitch && \
    mkdir -p /etc/cni/net.d && \
    mkdir -p /opt/cni/bin && \
    mkdir -p /usr/libexec/cni/

COPY --from=builder /go-controller/_output/go/bin/ovnkube /usr/bin/
COPY --from=builder /go-controller/_output/go/bin/ovn-kube-util /usr/bin/
COPY --from=builder /go-controller/_output/go/bin/ovn-k8s-cni-overlay /usr/libexec/cni/ovn-k8s-cni-overlay

COPY --from=cli /usr/bin/oc /usr/bin
RUN ln -s /usr/bin/oc /usr/bin/kubectl

# copy git commit number into image
COPY .git/HEAD /root/.git/HEAD
COPY .git/refs/heads/ /root/.git/refs/heads/

# ovnkube.sh is the entry point. This script examines environment
# variables to direct operation and configure ovn
COPY dist/images/ovnkube.sh /root/
COPY dist/images/ovn-debug.sh /root/

# iptables wrappers
COPY ./dist/images/iptables-scripts/iptables /usr/sbin/
COPY ./dist/images/iptables-scripts/iptables-save /usr/sbin/
COPY ./dist/images/iptables-scripts/iptables-restore /usr/sbin/
COPY ./dist/images/iptables-scripts/ip6tables /usr/sbin/
COPY ./dist/images/iptables-scripts/ip6tables-save /usr/sbin/
COPY ./dist/images/iptables-scripts/ip6tables-restore /usr/sbin/
COPY ./dist/images/iptables-scripts/iptables /usr/sbin/


WORKDIR /root
ENTRYPOINT /root/ovnkube.sh

LABEL \
        io.k8s.description="This is a component of OpenShift Container Platform that provides an overlay network using ovn." \
        com.redhat.component="ose-ovn-kubernetes-container" \
        maintainer="Phil Cameron <pcameron@redhat.com>" \
        name="openshift/ose-ovn-kubernetes" \
        License="GPLv2+" \
        io.k8s.display-name="ovn kubernetes" \
        io.openshift.build.source-location="https://github.com/openshift/ovn-kubernetes" \
        summary="This is a component of OpenShift Container Platform that provides an overlay network using ovn." \
        io.openshift.build.commit.url="https://github.com/openshift/ovn-kubernetes/commit/2808c2cbb256460d929491f33ec5858ceebb211c" \
        version="v4.4.0" \
        io.openshift.build.commit.id="2808c2cbb256460d929491f33ec5858ceebb211c" \
        release="201912202230" \
        vendor="Red Hat" \
        io.openshift.tags="openshift"


LABEL "authoritative-source-url"="registry.access.redhat.com" "distribution-scope"="public" "vendor"="Red Hat, Inc." "description"="This is a component of OpenShift Container Platform that provides an overlay network using ovn." "url"="https://access.redhat.com/containers/#/registry.access.redhat.com/openshift/ose-ovn-kubernetes/images/v4.4.0-201912202230" "vcs-type"="git" "architecture"="x86_64" "build-date"="2019-12-21T03:57:43.210685" "com.redhat.license_terms"="https://www.redhat.com/en/about/red-hat-end-user-license-agreements" "com.redhat.build-host"="cpt-1006.osbs.prod.upshift.rdu2.redhat.com" "vcs-ref"="2139b27cd2e49234abd661bd2097d7f753a2b265"
