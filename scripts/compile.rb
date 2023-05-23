#!/usr/bin/env ruby
require_relative "utils"

TARGET = ARGV.first
unless %w(macos-arm64 macos-x86_64 linux mingw).include? TARGET
  puts "make.rb {macos-arm64|macos-x86_64|linux|mingw}"
  exit 1
end
PREFIX = "build/#{TARGET}"
EXE_NAME="bismite-sprite-sheeter"+(TARGET=="mingw"?".exe":"")

#
# compile .rb
#
cp "src/sprite-sheeter.c", PREFIX
cp "src/sprite-sheeter.rb", PREFIX
cp "src/merge.rb", PREFIX
Dir.chdir(PREFIX){
  run "./merge.rb sprite-sheeter.rb compiled.rb"
}
run "#{PREFIX}/mruby/bin/mrbc -B code -o #{PREFIX}/sprite-sheeter.h #{PREFIX}/compiled.rb"

#
# compile .exe
#
DEFINES = %w(
  -DMRB_INT64
  -DMRB_UTF8_STRING
  -DMRB_NO_BOXING
  -DMRB_NO_DEFAULT_RO_DATA_P
  -DMRB_STR_LENGTH_MAX=0
  -DMRB_ARY_LENGTH_MAX=0
).join(" ")
CFLAGS = %w(-Wall -Werror-implicit-function-declaration -Wwrite-strings -std=gnu11 -O3 -g0).join(" ")

Dir.chdir(PREFIX){
  INCLUDE = "-Iinclude -Iinclude/SDL2"
  case TARGET
  when /macos/
    arch = "arm64"  if TARGET.end_with?("-arm64")
    arch = "x86_64" if TARGET.end_with?("-x86_64")
    run "clang #{CFLAGS} -arch #{arch} sprite-sheeter.c -o #{EXE_NAME} #{DEFINES} #{INCLUDE} -Llib -lmruby lib/libSDL2.a lib/libSDL2_image.a -liconv -lm -framework OpenGL -Wl,-framework,CoreAudio -Wl,-framework,AudioToolbox -Wl,-weak_framework,CoreHaptics -Wl,-weak_framework,GameController -Wl,-framework,ForceFeedback -lobjc -Wl,-framework,CoreVideo -Wl,-framework,Cocoa -Wl,-framework,Carbon -Wl,-framework,IOKit -Wl,-weak_framework,QuartzCore -Wl,-weak_framework,Metal"
    run "strip #{EXE_NAME}"
  when "linux"
    libs = "lib/libSDL2.a lib/libSDL2_image.a -pthread -lm -lrt"
    run "clang #{CFLAGS} sprite-sheeter.c -o #{EXE_NAME} #{DEFINES} #{INCLUDE} -Llib -lmruby #{libs}"
    run "strip #{EXE_NAME}"
  when "mingw"
    libs = %w(mruby SDL2main SDL2 SDL2_image).map{|l| "lib/lib#{l}.a" }.join(" ")
    run "x86_64-w64-mingw32-gcc sprite-sheeter.c -o #{EXE_NAME} #{DEFINES} #{INCLUDE} -Llib -lmingw32 #{libs} -lopengl32 -lws2_32 -mwindows -Wl,--dynamicbase -Wl,--nxcompat -Wl,--high-entropy-va -lm -ldinput8 -ldxguid -ldxerr8 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lshell32 -lsetupapi -lversion -luuid"
    run "x86_64-w64-mingw32-strip #{EXE_NAME}"
  end
}
