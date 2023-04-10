#!/usr/bin/env ruby
require_relative "scripts/utils"

TARGET = ARGV.first
unless %w(macos-arm64 macos-x86_64 linux mingw).include? TARGET
  puts "make.rb {macos-arm64|macos-x86_64|linux|mingw}"
  exit 1
end
PREFIX = "build/#{TARGET}"
puts "target : #{TARGET}"
mkdir_p "#{PREFIX}"

EXE_NAME="bismite-sprite-sheeter"+(TARGET=="mingw"?".exe":"")

COMMON_DOWNLOADS = %w(
  https://github.com/bismite/bin_packing/archive/refs/tags/v0.2.0.tar.gz
  bin_packing-0.2.0.tar.gz
  bin_packing
  https://github.com/mruby/mruby/archive/3.2.0.tar.gz
  mruby-3.2.0.tgz
  mruby
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
  COMMON_DOWNLOADS.each_slice(3){|url,filename,dirname|
    download url,filename
    mkdir_p dirname rescue nil
    run "tar xf #{filename} -C #{dirname} --strip-component 1"
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
cp "src/mruby-patch.diff", "#{PREFIX}/mruby"
Dir.chdir("#{PREFIX}/mruby"){
  # Patch to mruby
  run "patch -p1 -i mruby-patch.diff"
  run "rake"
}
# install mruby
Dir.chdir(PREFIX){
  cp_r "mruby/include", "./"
  cp_r "mruby/build/#{TARGET}/include", "./"
  cp_r "mruby/build/#{TARGET}/lib", "./"
}

#
# Compile bismite-sprite-sheeter
#
run "./scripts/compile.rb #{TARGET}"

#
# Pack
#
mkdir_p "#{PREFIX}/licenses/"
cp "src/licenses.txt", "#{PREFIX}/licenses/"
rm "#{PREFIX}/licenses/SDL2_mixer-2.6.3-LICENSE.txt"
cp "README.md", PREFIX
Dir.chdir(PREFIX){
  run "tar zcf bismite-sprite-sheeter.tgz #{EXE_NAME} README.md licenses/"
}
