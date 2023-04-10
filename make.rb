#!/usr/bin/env ruby
require_relative "scripts/utils"

MRUBY = "mruby-3.2.0"

TARGET = ARGV.first
unless %w(macos-arm64 macos-x86_64 linux mingw).include? TARGET
  puts "make.rb {macos-arm64|macos-x86_64|linux|mingw}"
  exit 1
end
PREFIX = "build/#{TARGET}"
puts "target : #{TARGET}"
mkdir_p "#{PREFIX}"
SPRITESHEETER="bismite-sprite-sheeter"
EXE_NAME=SPRITESHEETER+(TARGET=="mingw"?".exe":"")

COMMON_DOWNLOADS = %w(
  https://github.com/bismite/bin_packing/archive/refs/tags/v0.2.0.tar.gz
  bin_packing-0.2.0.tar.gz
  https://github.com/mruby/mruby/archive/3.2.0.tar.gz
  mruby.tgz
)
DOWNLOADS = {
  "linux" => %w(
    https://github.com/bismite/SDL-binaries/releases/download/linux-1.0.9/SDL-linux-1.0.9.tgz
  ),
  "macos-arm64" => %w(
    https://github.com/bismite/SDL-binaries/releases/download/macos-arm64-1.0.7/SDL-macos-arm64-1.0.7.tgz
  ),
  "macos-x86_64" => %w(
    https://github.com/bismite/SDL-binaries/releases/download/macos-x86_64-1.0.7/SDL-macos-x86_64-1.0.7.tgz
  ),
  "mingw" => %w(
    https://github.com/bismite/SDL-binaries/releases/download/mingw-1.0.4/SDL-mingw-1.0.4.tgz
  )
}

def download(url,filename=nil)
  if( (filename && File.file?(filename)) || File.file?(File.basename(url)))
    puts "#{filename} already exist"
    return
  end
  opt = ""
  if which "curl"
    opt += filename ? "-o #{filename}" : "-O"
    run "curl -JL#S #{opt} #{url}"
  elsif which "wget"
    opt += "-O #{filename}" if filename
    run "wget #{opt} #{url}"
  else
    raise "require curl or wget"
  end
end

Dir.chdir("#{PREFIX}") do
  COMMON_DOWNLOADS.each_slice(2){|url,filename|
    download url,filename
    run "tar xf #{filename}"
  }
  DOWNLOADS[TARGET].each{|url|
    download url
    run "tar xf #{File.basename url}"
  }
end

puts "compile mruby"
ENV["MRUBY_CONFIG"] = File.absolute_path "mruby_config/#{TARGET}.rb"
ENV["ARCH"] = "arm64"  if TARGET.end_with?("-arm64")
ENV["ARCH"] = "x86_64" if TARGET.end_with?("-x86_64")
ENV["MRUBY_CONFIG"] = File.absolute_path "mruby_config/macos.rb" if TARGET.start_with?("macos")
rm ENV["MRUBY_CONFIG"]+".lock" rescue nil
cp "src/mruby-patch.diff", "#{PREFIX}/#{MRUBY}"
Dir.chdir("#{PREFIX}/#{MRUBY}"){
  # Patch to mruby
  run "patch -p1 -i mruby-patch.diff"
  run "rake"
}
# install mruby
Dir.chdir(PREFIX){
  cp_r "#{MRUBY}/include", "./"
  cp_r "#{MRUBY}/build/#{TARGET}/include", "./"
  cp_r "#{MRUBY}/build/#{TARGET}/lib", "./"
}

#
# compile
#
cp "src/sprite-sheeter.c", PREFIX
cp "src/sprite-sheeter.rb", PREFIX
cp "scripts/compile.rb", PREFIX
Dir.chdir(PREFIX){
  run "./compile.rb sprite-sheeter.rb compiled.rb"
}
run "#{PREFIX}/#{MRUBY}/bin/mrbc -B code -o #{PREFIX}/sprite-sheeter.h #{PREFIX}/compiled.rb"
DEFINES = %w(
  -DMRB_INT64
  -DMRB_UTF8_STRING
  -DMRB_NO_BOXING
  -DMRB_NO_DEFAULT_RO_DATA_P
  -DMRB_STR_LENGTH_MAX=0
).join(" ")
CFLAGS = %w(-Wall -Werror-implicit-function-declaration -Wwrite-strings -std=gnu11 -O3 -g0).join(" ")

Dir.chdir(PREFIX){
  INCLUDE = "-Iinclude -Iinclude/SDL2"
  case TARGET
  when /macos/
    arch = ENV["ARCH"]
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

#
# License
#
mkdir_p "#{PREFIX}/licenses/"
cp "src/licenses.txt", "#{PREFIX}/licenses/"
rm "#{PREFIX}/licenses/SDL2_mixer-2.6.3-LICENSE.txt"

#
# Archive
#
cp "README.md", PREFIX
Dir.chdir(PREFIX){
  run "tar zcf #{SPRITESHEETER}.tgz #{EXE_NAME} README.md licenses/"
}
