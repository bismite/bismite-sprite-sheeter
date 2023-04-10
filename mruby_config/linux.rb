require_relative "common.rb"

INSTALL_PREFIX = "#{BUILD_DIR}/linux"
LIBS = %w(SDL2 SDL2_image)
INCLUDES = %w(include include/SDL2).map{|i| "#{INSTALL_PREFIX}/#{i}" }

MRuby::Build.new do |conf|
  toolchain :clang
end

MRuby::CrossBuild.new('linux') do |conf|
  toolchain :clang

  include_gems conf,"linux"

  conf.cc do |cc|
    cc.command = 'clang'
    cc.defines += COMMON_DEFINES
    cc.include_paths += INCLUDES
    cc.flags = COMMON_CFLAGS
  end

  conf.linker do |linker|
    linker.command = "clang"
    linker.library_paths += [ "#{INSTALL_PREFIX}/lib" ]
    linker.libraries += LIBS
  end
end
