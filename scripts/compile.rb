#!/usr/bin/env ruby
require "fileutils"

class Compile
  attr_reader :included_files, :line_count, :index, :code

  def initialize(mainfile,load_path=[])
    @mainfile = File.basename(mainfile)
    @load_path = [ File.dirname(mainfile) ] + load_path
    puts "load path: #{@load_path.inspect}"
    @included_files = {}
    @index = []
    @line_count = 0
    @code = ""
  end

  def run
    read @mainfile
    @header =<<EOS
begin
EOS
    @code = @header + @code
    @code +=<<EOS
rescue => e
  _FILE_INDEX_ = #{@index.to_s}
  table = []
  _FILE_INDEX_.reverse_each{|i|
    filename = i[0]
    start_line = i[1]
    end_line = i[2]
    table.fill filename, (start_line..end_line)
  }

  STDERR.puts "\#{e.class}: \#{e.message}"
  #STDERR.puts e.backtrace.join("\\n")
  e.backtrace.each{|b|
    m = b.chomp.split(":")
    if m.size < 2
      puts b
    else
      line = m[1].to_i - #{@header.lines.size} -1
      message = m[2..-1].join(":")
      original_filename = table[line]
      original_line = table[0..line].count original_filename
      STDERR.puts "\#{original_filename}:\#{original_line}:\#{message}"
    end
  }
end
EOS
  end

  def write(line)
    @code << line + "\n"
    @line_count += 1
  end

  def memory(file)
    path = File.expand_path file
    return false if @included_files[path]
    @included_files[path] = true
  end

  def read(filename)
    filename = filename+".rb" unless filename.end_with? ".rb"

    filepath = nil
    @load_path.find{|l|
      f = File.join(l,filename)
      if File.exists? f
        filepath = f
        break
      end
    }

    if filepath
      puts "read #{filepath}"
    else
      puts "#{filename} not found"
      return
    end

    unless memory filepath
      puts "#{filepath} already included."
      return
    end

    source = File.read(filepath)

    s = source.split "\n"
    s << "# #{filepath}"
    start_line = @line_count
    s.each{|l|
      if l.start_with? "$LOAD_PATH"
        write "# #{l}"
      elsif l.start_with? "require"
        next_file = l.chomp
        next_file.slice! "require"
        next_file.gsub! '"', ''
        next_file.gsub! "'", ''
        next_file.gsub! ' ', ''
        write "# #{l}"
        self.read next_file
      else
        write l
      end
    }

    @index << [filename,start_line,@line_count-1]
  end

  def handle_error_log(error_log)
    p error_log
    table = []
    @index.reverse_each{|i|
      filename = i[0]
      start_line = i[1]
      end_line = i[2]
      table.fill filename, (start_line..end_line)
    }

    error_log.each_line{|l|
      m = l.chomp.split(":")
      if m.size < 2
        puts l
      else
        line = m[1].to_i - @header.lines.size - 1
        message = m[2..-1].join(":")
        original_filename = table[line]
        if original_filename
          original_line = table[0..line].count original_filename
          puts "#{original_filename}:#{original_line}:#{message}"
        else
          puts l
        end
      end
    }
  end
end

# compile
INFILE=ARGV[0]
OUTFILE=ARGV[1]
compile = Compile.new INFILE, ["bin_packing-0.2.0/lib"]

begin
  compile.run
rescue SyntaxError => e
  exit 1
end

FileUtils::mkdir_p File.dirname OUTFILE
File.open(OUTFILE,"wb").write(compile.code)
