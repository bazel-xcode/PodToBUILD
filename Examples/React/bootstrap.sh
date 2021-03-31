set -x
# This is not trival and generally installed with npm
# Alternatively, add an entry in Pods.WORKSPACE with the latest URL for RN
# Note: on this release, there's an issue with this commit.
# this should be patched on somehow
# https://github.com/facebook/react-native/pull/28946
VERSION="0.63.3"

cleanup() {
    rm -rf react-native-${VERSION}.*
}

download_react_if_necessary() {
    if [[ "$(cat PodsHost/RN_VERSION)" == "$VERSION" ]]; then
        echo "Already updated to $VERSION"
        return
    fi

    PODIR=Vendor
    mkdir -p PodsHost
    echo $VERSION > PodsHost/RN_VERSION
    [[ -f react-native-${VERSION}.zip ]] || \
        curl -L https://github.com/facebook/react-native/archive/v${VERSION}.zip \
        -o react-native-${VERSION}.zip
    unzip -qu react-native-${VERSION}.zip

    mkdir -p $PODIR
    [[ ! -d $PODIR/React ]] \
        || rm -rf $PODIR/React
    mv react-native-${VERSION} $PODIR/React

    # prepare_command is unsupported these are right out of the podspecs
    sed -i '' \
        's,spec.prepare_command,#spec.prepare_command,g' \
        Vendor/React/third-party-podspecs/glog.podspec
}

trap cleanup EXIT
download_react_if_necessary
make update_xcodeproj gen_podfile_deps
