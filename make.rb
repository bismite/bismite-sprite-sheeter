#!/usr/bin/env ruby
require_relative "scripts/utils"
HOST = RUBY_PLATFORM.include?("darwin") ? "macos" : "linux"
TARGET = ARGV.first ? ARGV.first : HOST
exit 1 unless %w(macos linux mingw).include? TARGET
mkdir_p "build"

# name
SPRITESHEETER="bismite-sprite-sheeter"
EXE_NAME=SPRITESHEETER+(TARGET=="mingw"?".exe":"")

#
# Download
#
run "scripts/download.rb #{TARGET}"

#
# compile mruby
#
ENV["MRUBY_CONFIG"] = File.absolute_path "scripts/mruby_config/#{TARGET}.rb"
Dir.chdir("build/mruby"){ run "rake" }

#
# install mruby
#
Dir.chdir("build"){
  mkdir_p "lib"
  cp_r "mruby/include", "./"
}
case TARGET
when "macos"
  cp_r "build/mruby/build/macos-x86_64/include", "build/"
  run "lipo -create build/mruby/build/macos-x86_64/lib/libmruby.a build/mruby/build/macos-arm64/lib/libmruby.a -output build/lib/libmruby.a"
when "linux"
  cp_r "build/mruby/build/linux/include", "build/"
  cp "build/mruby/build/linux/lib/libmruby.a", "build/lib/libmruby.a"
when "mingw"
  cp_r "build/mruby/build/mingw/include", "build/"
  cp "build/mruby/build/mingw/lib/libmruby.a", "build/lib/libmruby.a"
end

#
# compile
#
run "./scripts/compile.rb src/sprite-sheeter.rb build/compiled.rb"
run "./build/mruby/bin/mrbc -B code -o build/sprite-sheeter.h build/compiled.rb"
cp "src/sprite-sheeter.c", "build/"
DEFINES="-DMRB_INT64 -DMRB_UTF8_STRING -DMRB_NO_BOXING"
Dir.chdir("build"){
  case TARGET
  when "macos"
    run "clang -Wall -O2 -std=gnu11 sprite-sheeter.c -o #{EXE_NAME} #{DEFINES} -Iinclude -Iinclude/SDL2 -Llib -lmruby lib/libSDL2.a lib/libSDL2_image.a lib/libmsgpackc.a -liconv -lm -framework OpenGL -Wl,-framework,CoreAudio -Wl,-framework,AudioToolbox -Wl,-weak_framework,CoreHaptics -Wl,-weak_framework,GameController -Wl,-framework,ForceFeedback -lobjc -Wl,-framework,CoreVideo -Wl,-framework,Cocoa -Wl,-framework,Carbon -Wl,-framework,IOKit -Wl,-weak_framework,QuartzCore -Wl,-weak_framework,Metal"
    run "strip #{EXE_NAME}"
  when "linux"
    run "clang -Wall -O2 -std=gnu11 sprite-sheeter.c -o #{EXE_NAME} #{DEFINES} -Iinclude -Llib -lmruby -lm -lmsgpackc `sdl2-config --cflags --libs` -lSDL2_image"
    run "strip #{EXE_NAME}"
  when "mingw"
    slibs = %w(mruby SDL2main SDL2 SDL2_image-static png z msgpackc).map{|l| "lib/lib#{l}.a" }.join(" ")
    run "x86_64-w64-mingw32-gcc sprite-sheeter.c -o #{EXE_NAME} #{DEFINES} -Iinclude -Iinclude/SDL2 -Llib -lmingw32 -lmruby #{slibs} -lopengl32 -lws2_32 -mwindows -Wl,--dynamicbase -Wl,--nxcompat -Wl,--high-entropy-va -lm -ldinput8 -ldxguid -ldxerr8 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lshell32 -lsetupapi -lversion -luuid"
    run "x86_64-w64-mingw32-strip #{EXE_NAME}"
  end
}

#
# License
#
cp "src/mruby-and-libraries-licenses.txt", "build/licenses/"
cp "LICENSE", "build/licenses/#{SPRITESHEETER}-LICENSE.txt"
bp_license = <<-EOS
bin_packing-0.2.0
MAK IT <info@makit.lv>

#{File.read("build/bin_packing-0.2.0/LICENSE")}
EOS
File.write "build/licenses/bin_packing-0.2.0-LICENSE.txt",bp_license

# Archive
cp "README.md", "build/"
exts_executable = TARGET=="mingw"?".exe":""
Dir.chdir("build"){
  run "tar zcf #{SPRITESHEETER}-#{TARGET}.tgz #{EXE_NAME} licenses/ README.md"
}
