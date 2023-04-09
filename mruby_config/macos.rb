require_relative "common.rb"

ARCH = ENV['ARCH']
raise "invalid ENV['ARCH']" unless %w(arm64 x86_64).include?(ARCH)

INSTALL_PREFIX = "#{BUILD_DIR}/macos-#{ARCH}"
LIBS = %w(SDL2 SDL2_image)
INCLUDES = %w(include include/SDL2).map{|i| "#{INSTALL_PREFIX}/#{i}" }

MRuby::Build.new do |conf|
  toolchain :clang
end

MRuby::CrossBuild.new("macos-#{ARCH}") do |conf|
  toolchain :clang

  include_gems conf,"macos-#{ARCH}"

  conf.cc do |cc|
    cc.command = 'clang'
    cc.defines += COMMON_DEFINES
    cc.include_paths += INCLUDES
    cc.flags = COMMON_CFLAGS + ["-arch #{ARCH}"]
  end

  conf.linker do |linker|
    linker.library_paths += [ "#{INSTALL_PREFIX}/lib" ]
    linker.libraries += LIBS
    linker.flags << "-framework OpenGL -arch #{ARCH}"
  end

end
