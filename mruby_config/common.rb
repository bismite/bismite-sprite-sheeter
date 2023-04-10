
BUILD_DIR = File.expand_path File.join __dir__, "..", "build"
COMMON_DEFINES = %w(MRB_INT64 MRB_UTF8_STRING MRB_NO_BOXING MRB_NO_DEFAULT_RO_DATA_P MRB_STR_LENGTH_MAX=0)
COMMON_CFLAGS = %w(-Wall -Werror-implicit-function-declaration -Wwrite-strings -std=gnu11 -O3 -g0)

def include_gems(conf,target)
  Dir.glob("#{root}/mrbgems/mruby-*/mrbgem.rake") do |x|
    g = File.basename File.dirname x
    conf.gem :core => g unless g =~ /^mruby-(bin-debugger|test)$/
  end
  conf.gem github: 'iij/mruby-iijson'
end
