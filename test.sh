#!/bin/bash

SPRITESHEETER=$1

mkdir -p build/test
rm -f build/test/out.png
${SPRITESHEETER} test/assets build/test
cp test/view.rb build/test
(cd build/test ; mruby view.rb)
