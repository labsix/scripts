#!/usr/bin/env bash

# This is designed to run on Ubuntu 16.04 or Debian 9

set -eu

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

main() {
    tempdir=$(mktemp -d)
    trap "rm -rf $tempdir" EXIT

    # set up users
    echo "Setting up user accounts."
    curl -fsSL https://raw.githubusercontent.com/labsix/scripts/master/syncusers | bash

    # install from repos
    echo "Installing programs from the package repository."
    apt update
    apt install -y \
        git mercurial vim htop iotop axel aria2 silversearcher-ag \
        build-essential libevent-dev libncurses-dev \
        autojump python-pip python-virtualenv python-dev \
        vnstat apt-transport-https lm-sensors bc \
        rsync python-numpy python-scipy \
        gfortran libblas-dev liblapack-dev \
        libjpeg-dev zlib1g-dev python-opencv \
        linux-headers-$(uname -r)

    # build from source
    echo "Building some software from source."
    cd "$tempdir"
    wget 'https://github.com/tmux/tmux/releases/download/2.5/tmux-2.5.tar.gz'
    tar xvf tmux-2.5.tar.gz
    cd tmux-2.5
    ./configure
    make -j12
    make install
    cd "$tempdir"
    wget 'https://downloads.sourceforge.net/project/zsh/zsh/5.4.1/zsh-5.4.1.tar.xz'
    tar xvf zsh-5.4.1.tar.xz
    cd zsh-5.4.1
    ./configure
    make -j12
    make install
    sh -c 'echo "/usr/local/bin/zsh" >> /etc/shells'

    # install NVIDIA stuff
    echo "Installing NVIDIA Drivers, CUDA, and CUDNN."
    cd "$tempdir"
    fetch http://i.anish.io/labsix/NVIDIA-Linux-x86_64-390.25.run       d1ce4a1cde7ddb59e08b69c306c0a8ba48389378
    fetch http://i.anish.io/labsix/cuda_9.0.176_384.81_linux-run        7e30b16a3bd72c7e67cdf98f3ca62804b1ba7546
    fetch http://i.anish.io/labsix/cudnn-9.0-linux-x64-v7.4.2.24.tgz    aa6484edb3893e00d1b44c424d9ece7b86a1f083
    sh NVIDIA-Linux-x86_64-390.25.run -s
    sh cuda_9.0.176_384.81_linux-run --silent --toolkit
    tar xf cudnn-9.0-linux-x64-v7.4.2.24.tgz
    cp cuda/include/* /usr/local/cuda/include/
    cp cuda/lib64/* /usr/local/cuda/lib64/

    echo "All done."
}

# $1 is filename
# $2 is expected sha
check_sha1() {
    computed=$(sha1sum "$1" 2>/dev/null | awk '{print $1}') || return 1
    if [ "$computed" == "$2" ]; then
        return 0;
    else
        return 1;
    fi
}

# $1 is URL
# $2 is the checksum
fetch() {
    echo "downloading $1"
    f=${1##*/}
    wget -q $1 -O $f
    if check_sha1 $f $2; then
        echo "downloaded $f"
    else
        echo "HASH MISMATCH, SHA1($f) != $2"
        return 1
    fi
}

main
