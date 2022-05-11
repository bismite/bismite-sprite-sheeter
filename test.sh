#!/bin/bash

mkdir -p build/test
rm -f build/test/out.png
./build/bismite-sprite-sheeter test/assets build/test
cp test/view.rb build/test
(cd build/test ; mruby view.rb)
