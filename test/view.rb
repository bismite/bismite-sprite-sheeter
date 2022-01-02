#!/usr/bin/env bismite-run

Bi.init 480,320,title:__FILE__,highdpi:false

# Sprite Sheet
tex = Bi::Texture.new("out.png",false)
dat = MessagePack.unpack(File.read("out.dat"))

# test
check = Bi::TextureMapping.new(tex,*dat["test/assets/check.png"]).to_sprite
tester = Bi::TextureMapping.new(tex,*dat["test/assets/tester.png"]).to_sprite
tester.set_position 16,16

# layer
layer = Bi::Layer.new
layer.root = check
layer.root.add tester
Bi::add_layer layer
layer.set_texture 0, tex

Bi::start_run_loop
