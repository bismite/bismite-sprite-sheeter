require_relative "common.rb"

INSTALL_PREFIX = "#{BUILD_DIR}/mingw"
LIBS = %w(SDL2 SDL2_image)
INCLUDES = %w(include include/SDL2).map{|i| "#{INSTALL_PREFIX}/#{i}" }

MRuby::Build.new do |conf|
  toolchain :clang
end

MRuby::CrossBuild.new('mingw') do |conf|
  toolchain :gcc
  conf.host_target = "mingw"

  include_gems conf,"mingw"

  conf.cc do |cc|
    cc.command = 'x86_64-w64-mingw32-gcc'
    cc.defines += COMMON_DEFINES + %w(DISABLE_CLOCK_GETTIME)
    cc.include_paths += INCLUDES
    cc.flags = COMMON_CFLAGS
    cc.flags << "-Dmain=SDL_main"
  end

  conf.linker do |linker|
    linker.command = 'x86_64-w64-mingw32-gcc'
    linker.library_paths << "#{INSTALL_PREFIX}/lib"
    # linker.libraries += %w(opengl32 ws2_32 mingw32 SDL2main SDL2 SDL2_image)
    linker.libraries += %w(ws2_32)
    linker.flags_after_libraries << "#{INSTALL_PREFIX}/lib/libSDL2_image.a -lmingw32 #{INSTALL_PREFIX}/lib/libSDL2main.a #{INSTALL_PREFIX}/lib/libSDL2.a -mwindows  -Wl,--dynamicbase -Wl,--nxcompat -Wl,--high-entropy-va -lm -ldinput8 -ldxguid -ldxerr8 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lshell32 -lsetupapi -lversion -luuid"
    linker.flags_after_libraries << " -static-libgcc -mconsole"
  end

  conf.exts do |exts|
    exts.executable = '.exe'
  end
end
