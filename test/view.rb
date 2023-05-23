#!/usr/bin/env bismite-run

Bi.init 480,320,title:__FILE__,highdpi:false

# Sprite Sheet
sheet_max = 0
$dat = JSON.load(File.read("sheet.json")).map{|d|
  name = d.shift
  num = d.shift
  sheet_max = num if sheet_max < num.to_i
  p [name,d]
  [name, [num, d] ]
}.to_h
$texs = (0..sheet_max).map{|i| Bi::Texture.new "sheet_#{i}.png" }
p $texs

def sprite(name)
  d = $dat[name]
  p d.first
  tex = $texs[d.first]
  p tex
  p [name, d.last]
  tex.to_sprite( *d.last )
end

# Sprites
face01 = sprite("assets/face01.png").set_position 0,0
face02 = sprite("assets/face02.png").set_position 150,0
face03 = sprite("assets/face03.png").set_position 300,0
star = sprite("assets/star.png")

# layer
layer = Bi::Layer.new
$texs.each_with_index{|t,i| layer.set_texture i,t }
layer.root = Bi::Node.new
layer.root.add star
layer.root.add face01
layer.root.add face02
layer.root.add face03
Bi::add_layer layer

Bi::start_run_loop
