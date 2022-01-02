
require_relative "common.rb"

SCRIPTS_DIR = File.expand_path File.join __dir__, "..", "..", "scripts"
INSTALL_PREFIX = BUILD_DIR
LIBS = %w(SDL2 SDL2_image msgpackc)
INCLUDES = %w(include include/SDL2).map{|i| "#{INSTALL_PREFIX}/#{i}" }
COMMON_CFLAGS = %w(-Wall -Werror-implicit-function-declaration -Wwrite-strings -std=gnu11 -O3)
COMMON_DEFINES = %w(MRB_INT64 MRB_UTF8_STRING MRB_NO_BOXING)

MRuby::Build.new do |conf|
  toolchain :clang
end

MRuby::CrossBuild.new('macos-arm64') do |conf|
  toolchain :clang

  include_gems conf,"macos"

  conf.cc do |cc|
    cc.command = 'clang'
    cc.defines += COMMON_DEFINES
    cc.include_paths += INCLUDES
    cc.flags = COMMON_CFLAGS + %w(-arch arm64)
  end

  conf.linker do |linker|
    linker.command = "clang"
    linker.library_paths += [ "#{INSTALL_PREFIX}/lib", "#{BUILD_DIR}/macos/mruby/build/macos-arm64/lib"]
    linker.libraries += LIBS
    linker.flags << "-arch arm64"
  end
end

MRuby::CrossBuild.new('macos-x86_64') do |conf|
  toolchain :clang

  include_gems conf,"macos"

  conf.cc do |cc|
    cc.command = 'clang'
    cc.defines += COMMON_DEFINES
    cc.include_paths += INCLUDES
    cc.flags = COMMON_CFLAGS + %w(-arch x86_64)
  end

  conf.linker do |linker|
    linker.command = "clang"
    linker.library_paths += ["#{INSTALL_PREFIX}/lib", "#{BUILD_DIR}/macos/mruby/build/macos-x86_64/lib"]
    linker.libraries += LIBS
    linker.flags << "-arch x86_64"
  end
end
