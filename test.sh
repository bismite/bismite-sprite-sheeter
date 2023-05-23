#!/bin/bash
set -e

case `uname -s` in
Linux)
  TARGET=linux
  ;;
Darwin)
  TARGET=macos-arm64
  ;;
esac

mkdir -p build/test
rm -f build/test/out.png

EXE="./build/${TARGET}/bismite-sprite-sheeter test/assets build/test"
echo "test ${EXE}"
echo "----"
${EXE}
echo "----"

cp test/view.rb build/test
(cd build/test ; mruby view.rb)
