require_relative "common.rb"

SCRIPTS_DIR = File.expand_path File.join __dir__, "..", "..", "scripts"

MRuby::Build.new do |conf|
  toolchain :clang
end

MRuby::CrossBuild.new('mingw') do |conf|
  toolchain :gcc
  conf.host_target = "mingw"

  include_gems conf,"mingw"

  conf.cc do |cc|
    cc.command = 'x86_64-w64-mingw32-gcc'
    cc.defines += %w(MRB_INT64 MRB_UTF8_STRING MRB_NO_BOXING)
    cc.include_paths << "#{BUILD_DIR}/include"
    cc.include_paths << "#{BUILD_DIR}/include/SDL2"
    cc.flags = %W(-O3 -std=gnu11 -DNDEBUG -Wall -Werror-implicit-function-declaration -Wwrite-strings)
    cc.flags << "-Dmain=SDL_main"
  end

  conf.linker do |linker|
    linker.command = 'x86_64-w64-mingw32-gcc'
    linker.library_paths << "#{BUILD_DIR}/bin"
    linker.library_paths << "#{BUILD_DIR}/lib"
    linker.library_paths << "#{BUILD_DIR}/mruby/build/mingw/lib"
    linker.libraries += %w(opengl32 ws2_32 msgpackc mingw32 SDL2main SDL2 SDL2_image)
    linker.flags_after_libraries << "-static-libgcc -mconsole"
  end

  conf.exts do |exts|
    exts.executable = '.exe'
  end
end
