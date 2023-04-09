require_relative "common.rb"

SCRIPTS_DIR = File.expand_path File.join __dir__, "..", "..", "scripts"

MRuby::Build.new do |conf|
  toolchain :clang
end

MRuby::CrossBuild.new('linux') do |conf|
  toolchain :clang

  include_gems conf,"linux"

  conf.cc do |cc|
    cc.command = 'clang'
    cc.defines += %w(MRB_INT64 MRB_UTF8_STRING MRB_NO_BOXING)
    cc.include_paths << "#{BUILD_DIR}/include"
    cc.flags = %W(-Os -std=gnu11 -Wall -Werror-implicit-function-declaration -Wwrite-strings)
    cc.flags << "`sdl2-config --cflags`"
  end

  conf.linker do |linker|
    linker.command = "clang"
    linker.library_paths += [ "#{BUILD_DIR}/lib", "#{BUILD_DIR}/mruby/build/linux/lib"]
    linker.libraries += %W(SDL2 SDL2_image)
  end
end
