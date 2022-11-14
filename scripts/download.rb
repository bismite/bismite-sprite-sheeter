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
  ),
  "macos" => %w(
    https://github.com/bismite/SDL-macOS-UniversalBinaries/releases/download/1.3.1/SDL-macOS-UniversalBinaries.tgz
    SDL-macOS-UniversalBinaries.tgz
    f80cb577a38ad6bfa2f24f1463d8adb8
  ),
  "mingw" => %w(
    https://github.com/bismite/SDL-x86_64-w64-mingw32/releases/download/1.1.1/SDL-x86_64-w64-mingw32.tgz
    SDL-x86_64-w64-mingw32.tgz
    9d4f107c123ee8a05e697e3dae453f99
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
  mkdir_p "lib"
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
