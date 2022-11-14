
BUILD_DIR = File.expand_path File.join __dir__, "..", "..", "build"

def include_gems(conf,target)
  Dir.glob("#{root}/mrbgems/mruby-*/mrbgem.rake") do |x|
    g = File.basename File.dirname x
    conf.gem :core => g unless g =~ /^mruby-(bin-debugger|test)$/
  end
  conf.gem github: 'iij/mruby-dir'
  conf.gem github: 'iij/mruby-iijson'
end
