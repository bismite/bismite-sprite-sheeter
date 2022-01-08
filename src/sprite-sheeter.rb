# for bin_packing
class Fixnum
  def size
    8
  end
end
require "bin_packing.rb"

class Rectangle < BinPacking::Box
  attr_accessor :img, :filename
  def initialize(w,h,img,filename)
    super w,h
    @img = img
    @filename = filename
  end
end

class Files
  attr_reader :files
  def initialize(dir)
    @files = []
    search(dir,"")
  end
  def search(dir,parent)
    Dir.entries(dir).each{|f|
      next if f.start_with?(".")
      path = File.join dir,f
      r = if File.directory? path
        search path, File.join(parent,f)
      elsif path.downcase.end_with? ".png"
        @files << path
      end
    }
  end
end

#
# initialize
#
if ARGV.size!=5
  puts "usage: bismite-sprite-sheeter CanvasWidth[px] CanvasHeight[px] Margin[px] srcdir dstdir"
  exit 1
end
CANVAS_W = ARGV.shift.to_i
CANVAS_H = ARGV.shift.to_i
MARGIN = ARGV.shift.to_i
SRCDIR = ARGV.shift
DSTDIR = ARGV.shift
# HEURISTICS = BinPacking::Heuristics::BestAreaFit.new
# HEURISTICS = BinPacking::Heuristics::BestLongSideFit.new
# HEURISTICS = BinPacking::Heuristics::BestShortSideFit.new
HEURISTICS = BinPacking::Heuristics::BottomLeft.new
hname=HEURISTICS.class.name.split('::').last
puts "#{CANVAS_W},#{CANVAS_W} Margin:#{MARGIN} Src:#{SRCDIR} Dst:#{DSTDIR} Heuristics:#{hname}"

#
# prepare
#
bin = BinPacking::Bin.new(CANVAS_W, CANVAS_H, HEURISTICS)
canvas= Image.new CANVAS_W,CANVAS_H
files = Files.new(SRCDIR).files
basename = File.basename(SRCDIR)
baselen = SRCDIR.size
boxes = files.map{|f|
  img = Image.read(f)
  filename = File.join(basename, f[baselen..-1])
  box = Rectangle.new( img.w+MARGIN*2, img.h+MARGIN*2, img, filename )
  box.can_rotate = false
  box
}.sort{|a,b| (b.width*b.height) <=> (a.width*a.height) }
# }.sort{|a,b| a.width <=> b.width }
# }.sort{|a,b| a.height <=> b.height }
# }.sort{|a,b| (a.width > a.height ? a.width : a.height) <=> (b.width > b.height ? b.width : b.height) }

#
# Packing
#
remaining_boxes = boxes.reject{|box| bin.insert(box) }
unless remaining_boxes.empty?
  puts "#{remaining_boxes.size}/#{boxes.size} images Out of Bounds"
end

#
# draw image
#
bin.boxes.each{|b|
  f = b.filename
  img = b.img
  canvas.blit! img, b.x+MARGIN, b.y+MARGIN
}

#
# Save Image and Layout Data
#
canvas.save File.join(DSTDIR,"out.png")
dat = bin.boxes.map{|b|
  [ b.filename, [b.x+MARGIN, b.y+MARGIN, b.width-MARGIN*2, b.height-MARGIN*2] ]
}.to_h
File.open( File.join(DSTDIR,"out.dat"), "wb"){|f| f.write dat.to_msgpack }
File.open( File.join(DSTDIR,"out.json"), "wb"){|f| f.write dat.to_json }
