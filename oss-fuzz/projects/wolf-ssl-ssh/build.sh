#!/bin/bash -eu

# Global configuration
export LIBFUZZER_A_PATH="$LIB_FUZZING_ENGINE"
export FUZZERS_INCLUDE_PATH=$(realpath $SRC/fuzzers/include)
export WOLFSSL_BASE_CONFIGURE_PARAMS="--enable-static --disable-examples --disable-crypttests"
if [[ $CFLAGS = *sanitize=memory* ]]
then
    export WOLFSSL_BASE_CONFIGURE_PARAMS="$WOLFSSL_BASE_CONFIGURE_PARAMS --disable-asm"
fi

# For applying patches, if any
git config --global user.email "guidovranken@gmail.com"
git config --global user.name "Guido Vranken"

# Patch wolfSSL
    cd $SRC/wolfssl

    git fetch origin pull/2624/head:pr2624 # Fix build failure (https://github.com/wolfSSL/wolfssl/issues/2639)
    git merge --no-edit pr2624

    # Apply additional patches if desired

# Patch wolfSSH
    cd $SRC/wolfssh

    # Apply additional patches if desired

# Build libfuzzer-gv -- needed for intensity and allocation guided fuzzing
    cd $SRC/libfuzzer-gv
    # Some patches to make libfuzzer-gv compile in this environment
        sed -i 's/ALWAYS_INLINE//g' *.h *.cpp
        sed -i 's/^.*__attribute__((always_inline)).*$//g' FuzzerDefs.h
        sed -i 's/clang++/clang++ -stdlib=libc++/g' Makefile
    make -j$(nproc)
    export LIBFUZZER_GV_A_PATH=$(realpath libFuzzer.a)

# Build wolfSSL + fuzzers
    /bin/bash $SRC/build_wolfssl_fuzzers.sh

# Build wolfSSH + fuzzers
    # 32 bit build of wolfSSH currenly fails
    # See: https://github.com/wolfSSL/wolfssh/issues/221
    # Remove this restriction once that bug is resolved
    if [[ $CFLAGS != *-m32* ]]
    then
        # Build wolfSSH + wolfSSL + fuzzers
        /bin/bash $SRC/build_wolfssh_fuzzers.sh
    fi