#!/usr/bin/env ruby
require_relative "utils"

#
# License file
#
cp "src/mruby-and-libraries-licenses.txt", "build/licenses/"
cp "LICENSE", "build/licenses/sprite-sheeter-LICENSE.txt"

bp_license = <<-EOS
bin_packing-0.2.0
MAK IT <info@makit.lv>

#{File.read("build/bin_packing-0.2.0/LICENSE")}
EOS
File.write "build/licenses/bin_packing-0.2.0-LICENSE.txt",bp_license
