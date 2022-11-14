#!/usr/bin/env bismite-run

Bi.init 480,320,title:__FILE__,highdpi:false

# Sprite Sheet
tex = Bi::Texture.new "sheet_0.png"
dat = JSON.load(File.read("sheet.json")).map{|d|
  name = d.shift
  num = d.shift # trash
  p [name,d]
  [name, d]
}.to_h

# face
face01 = tex.to_sprite( *dat["assets/face01.png"] )
face01.set_position 0,0
face02 = tex.to_sprite( *dat["assets/face02.png"] )
face02.set_position 150,0
face03 = tex.to_sprite( *dat["assets/face03.png"] )
face03.set_position 300,0

# layer
layer = Bi::Layer.new
layer.set_texture 0, tex
layer.root = Bi::Node.new
layer.root.add face01
layer.root.add face02
layer.root.add face03
Bi::add_layer layer

Bi::start_run_loop
