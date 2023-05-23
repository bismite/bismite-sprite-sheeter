# for bin_packing
class Fixnum
  def size
    8
  end
end
require "bin_packing.rb"

class Image
  attr_reader :crop_x, :crop_y, :crop_w, :crop_h
  attr_reader :crc
  attr_accessor :canvas_number
  attr_reader :crop_enabled
end

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
      if File.directory? path
        search path, File.join(parent,f)
      elsif path.downcase.end_with? ".png"
        @files << path
      end
    }
  end
end

def sort_by_area(boxes)
  boxes.sort{|a,b| (b.width*b.height) <=> (a.width*a.height) }
end
def sort_by_width(boxes)
  boxes.sort{|a,b| b.width <=> a.width }
end
def sort_by_height(boxes)
  boxes.sort{|a,b| b.height <=> a.height }
end
def sort_by_longer(boxes)
  boxes.sort{|a,b| (b.width > b.height ? b.width : b.height) <=> (a.width > a.height ? a.width : a.height) }
end
def sort_by_name(boxes)
  boxes.sort{|a,b| a.filename <=> b.filename }
end
def sort_by_random(boxes)
  srand
  boxes.shuffle
end

def pack_dat(filename,b,crop_geometry)
  return nil unless b.img.canvas_number
  crop_geometry = [ b.img.crop_x,b.img.crop_y,b.img.w,b.img.h ] unless crop_geometry
  [
    filename,
    b.img.canvas_number,
    b.x+MARGIN, b.y+MARGIN, b.width-MARGIN*2, b.height-MARGIN*2,
    crop_geometry
  ].flatten
end

#
# initialize
#
if ARGV.size!=2
  puts "bismite-sprite-sheeter 4.0.3"
  puts "usage: bismite-sprite-sheeter srcdir dstdir"
  exit 1
end
SRCDIR = ARGV.shift
DSTDIR = ARGV.shift
ROOT = File.basename(SRCDIR)

begin
  config = JSON::parse File.read(File.join(SRCDIR,"config.json"))
rescue => e
  config = {}
end
begin
  crop_list = JSON::parse File.read(File.join(SRCDIR,"crop.json"))
rescue => e
  crop_list = []
end
crop_list = crop_list.map{|k,v| [ File.join(ROOT,k), v ] }.to_h

CANVAS_W = config["width"] ? config["width"].to_i : 4096
CANVAS_H = config["height"] ? config["height"].to_i : 4096
MARGIN = config["margin"] ? config["margin"].to_i : 0
case config["heuristics"]
  when "BestAreaFit"
    HEURISTICS = BinPacking::Heuristics::BestAreaFit.new
  when "BestLongSideFit"
    HEURISTICS = BinPacking::Heuristics::BestLongSideFit.new
  when "BestShortSideFit"
    HEURISTICS = BinPacking::Heuristics::BestShortSideFit.new
  else
    HEURISTICS = BinPacking::Heuristics::BottomLeft.new
end
EXCLUDE_CROP = config["exclude_crop"] ? config["exclude_crop"].map{|f| File.join(ROOT,f) } : []
SORT_METOD = config["sort"]

hname=HEURISTICS.class.name.split('::').last
puts "#{CANVAS_W},#{CANVAS_W} Margin:#{MARGIN} Src:#{SRCDIR} Dst:#{DSTDIR} Heuristics:#{hname}"

#
# prepare
#
canvas= Image.new CANVAS_W,CANVAS_H
files = Files.new(SRCDIR).files
baselen = SRCDIR.size
crc_to_box = {}
dups = []
boxes = []

files.each{|f|
  filename = File.join ROOT, f.delete_prefix(SRCDIR)
  crop_enabled = true
  crop_enabled = false if EXCLUDE_CROP.any?{|e| filename.start_with? e }
  crop_enabled = false if crop_list[filename] # already cropped
  img = Image.read(f,crop_enabled)
  puts "#{f} #{img.w}x#{img.h} CRC32:#{'0x%x'%img.crc} crop:#{img.crop_enabled}"
  box = Rectangle.new( img.crop_w+MARGIN*2, img.crop_h+MARGIN*2, img, filename )
  box.can_rotate = false
  if crc_to_box[img.crc]
    dups << box
  else
    crc_to_box[img.crc] = box
    boxes << box
  end
}

# Sort
boxes = case config["sort"]
  when "longer"
    sort_by_longer boxes
  when "height"
    sort_by_height boxes
  when "width"
    sort_by_width boxes
  when "area"
    sort_by_area boxes
  when "random"
    sort_by_random boxes
  else
    sort_by_name boxes
end

#
# Packing
#
dat = []
count = 0
loop do
  break if boxes.empty?
  puts "packing #{boxes.size} images..."
  tmp = boxes.size
  bin = BinPacking::Bin.new(CANVAS_W, CANVAS_H, HEURISTICS)
  remaining_boxes = boxes.reject{|box| bin.insert(box) }
  if remaining_boxes.size == tmp
    puts "packing error."
    exit 1
  end

  # Draw
  bin.boxes.each{|b|
    f = b.filename
    img = b.img
    img.canvas_number = count
    canvas.blit! img, b.x+MARGIN, b.y+MARGIN, img.crop_x,img.crop_y,img.crop_w,img.crop_h
  }
  img_name = File.join(DSTDIR,"sheet_#{count}.png")
  canvas.save img_name
  puts "#{img_name} saved."

  # Dat
  dat += boxes.map{|b| pack_dat( b.filename, b, crop_list[b.filename] ) }.compact

  #
  unless remaining_boxes.empty?
    puts "#{remaining_boxes.size}/#{boxes.size} images Out of Bounds"
  end
  boxes = remaining_boxes
  canvas.clear
  count += 1
end

#
# Duplicated
#
dat += dups.map{|d| pack_dat( d.filename, crc_to_box[d.img.crc], crop_list[d.filename] ) }.compact

#
# Save
#
File.open( File.join(DSTDIR,"sheet.json"), "wb"){|f| f.write dat.to_json }
