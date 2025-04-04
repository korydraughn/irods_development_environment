# syntax=docker/dockerfile:1.5

FROM almalinux:8

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        epel-release \
        wget \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        ccache \
        cmake \
        python3-devel \
        python3-distro \
        python3-jsonschema \
        python3-psutil \
        python3-pyodbc \
        python3-requests \
        openssl \
        openssl-devel \
        lsof \
        postgresql-server \
        unixODBC-devel \
        which \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        dnf-plugin-config-manager \
    && \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    dnf config-manager -y --add-repo https://packages.irods.org/renci-irods.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    dnf config-manager -y --add-repo https://core-dev.irods.org/renci-irods-core-dev.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods-core-dev && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        'irods-externals*' \
    && \
    rm -rf /tmp/*

# NOTE: This step cannot be combined with the installation step(s) above. Certain packages will
# not be installed until certain other packages are installed. It's very sad and confusing.
#
# For almalinux:8, the powertools repository should be enabled so that certain developer
# tools such as ninja-build and help2man can be installed.
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        dnf-plugins-core \
    && \
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf config-manager --set-enabled powertools \
    && \
    dnf install -y \
        git \
        pam-devel \
        fuse-devel \
        libarchive-devel \
        libcurl-devel \
        bzip2-devel \
        libxml2-devel \
        make \
        gcc \
        gcc-c++ \
        rpm-build \
        sudo \
        systemd-devel \
        ninja-build \
        help2man \
        python3-packaging \
        gcc-toolset-11-gcc \
        gcc-toolset-11-gcc-c++ \
        gcc-toolset-11-libstdc++-devel \
        flex \
        bison \
    && \
    rm -rf /tmp/*

# For Python3 modules not available as packages:
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    dnf install -y \
        python3-pip \
        cmake \
        spdlog-devel \
    && \
    python3 -m pip install \
        lief \
            --global-option="--lief-no-cache" \
            --global-option="--ninja" \
            --global-option="--lief-no-pe" \
            --global-option="--lief-no-macho" \
            --global-option="--lief-no-android" \
            --global-option="--lief-no-art" \
            --global-option="--lief-no-vdex" \
            --global-option="--lief-no-oat" \
            --global-option="--lief-no-dex" \
    && \
    rm -rf /tmp/*

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ENV file_extension="rpm"
ENV package_manager="dnf"

ENV CCACHE_DIR="/irods_build_cache"
# Default to a reasonably large cache size
ENV CCACHE_MAXSIZE="64G"
# Allow for a lot of files (1.5M files, 300 per directory)
ENV CCACHE_NLEVELS="3"
# Allow any uid to use cache
ENV CCACHE_UMASK="000"

COPY --chmod=755 build_and_copy_packages_to_dir.sh /
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
