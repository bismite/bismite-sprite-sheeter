#!/usr/bin/env ruby
require_relative "utils"
HOST = RUBY_PLATFORM.include?("darwin") ? "macos" : "linux"
TARGET = ARGV.first ? ARGV.first : HOST
exit 1 unless %w(macos linux mingw).include? TARGET

mkdir_p "build"

common_downloads = %w(
  https://github.com/bismite/bin_packing/archive/refs/tags/v0.2.0.tar.gz
  bin_packing-0.2.0.tar.gz
  3047812427f8d5876c7bc1e47b702b46
  https://github.com/mruby/mruby/archive/3.0.0.tar.gz
  mruby.tgz
  381c36a37c722b3568a932306cc63e59
)
downloads = {
  "linux" => %w(
    https://github.com/bismite/msgpack-c-binary/releases/download/0.1.12/msgpack-c-linux.tgz
    msgpack-c-linux.tgz
    36f44c77a3b4cd702063323d185e0b9e
  ),
  "macos" => %w(
    https://github.com/bismite/msgpack-c-binary/releases/download/0.1.12/msgpack-c-macos.tgz
    msgpack-c-macos.tgz
    5950b8e7925bf21a938e8c9c9dce31fd
    https://github.com/bismite/SDL-macOS-UniversalBinaries/releases/download/1.2/SDL-macOS-UniversalBinaries.tgz
    SDL-macOS-UniversalBinaries.tgz
    bd9ffdf08e908da2b88c3222205ca701
  ),
  "mingw" => %w(
    https://github.com/bismite/SDL-x86_64-w64-mingw32/releases/download/0.3.2/SDL-x86_64-w64-mingw32.tgz
    SDL-x86_64-w64-mingw32.tgz
    a02f2ecc1e44b0bb4c01a4bdd9cf6d96
    https://github.com/bismite/msgpack-c-binary/releases/download/0.1.12/msgpack-c-x86_64-w64-mingw32.tgz
    msgpack-c-x86_64-w64-mingw32.tgz
    fa27a75e956fd34f0c4436e2caf36aca
  )
}

(common_downloads+downloads[TARGET]).each_slice(3){|url,filename,md5|
  puts "download #{url}"
  filepath = File.join "build", filename
  if File.exists?(filepath) and File.file?(filepath) and Digest::MD5.hexdigest(File.read(filepath))
    puts "#{filepath} already downloaded."
  else
    if which "curl"
      run "curl -JL#S -o #{filepath} #{url}"
    elsif which "wget"
      run "wget -O #{filepath} #{url}"
    else
      raise "require curl or wget"
    end
  end
  run "tar xf #{filepath} -C build/" if filename.end_with? "gz"
}

Dir.chdir("build"){
  ln_sf "mruby-3.0.0", "mruby"
  cp_r "msgpack-c/include", "./", remove_destination:true
  mkdir_p "lib"
  cp_r "msgpack-c/lib/libmsgpackc.a", "./lib/", remove_destination:true
}

case TARGET
when "macos"
  Dir.chdir("build"){
    cp_r "SDL-macOS-UniversalBinaries/include", "./", remove_destination:true
    cp_r "SDL-macOS-UniversalBinaries/lib", "./", remove_destination:true
    cp_r "SDL-macOS-UniversalBinaries/licenses", "./", remove_destination:true
    rm Dir["licenses/mpg123-*"]
    rm Dir["licenses/SDL2_mixer-*"]
  }
when "linux"
  # nop
when "mingw"
  rm Dir["licenses/mpg123-*"]
  rm Dir["licenses/SDL2_mixer-*"]
end
