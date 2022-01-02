#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/irep.h>
#include <mruby/dump.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/string.h>
#include <SDL_image.h>
#include "sprite-sheeter.h"

static void mrb_image_free(mrb_state *mrb,void* p){ SDL_FreeSurface(p); }
static struct mrb_data_type const mrb_image_data_type = { "Image", mrb_image_free };

static mrb_value mrb_bi_image_initialize(mrb_state *mrb, mrb_value self)
{
  mrb_int w,h;
  mrb_get_args(mrb, "ii", &w,&h);
  SDL_Surface* img = SDL_CreateRGBSurfaceWithFormat(0,w,h,32,SDL_PIXELFORMAT_RGBA32);
  DATA_PTR(self) = img;
  DATA_TYPE(self) = &mrb_image_data_type;
  return self;
}

static mrb_value mrb_bi_image_read(mrb_state *mrb, mrb_value self)
{
  const char* path;
  mrb_get_args(mrb, "z", &path);
  SDL_Surface* img = IMG_Load(path);
  SDL_SetSurfaceBlendMode(img,SDL_BLENDMODE_NONE);
  struct RClass *klass = mrb_class_get(mrb,"Image");
  struct RData *data = mrb_data_object_alloc(mrb,klass,img,&mrb_image_data_type);
  return mrb_obj_value(data);
}

static mrb_value mrb_bi_image_w(mrb_state *mrb, mrb_value self)
{
  SDL_Surface* img = DATA_PTR(self);
  return mrb_fixnum_value(img->w);
}

static mrb_value mrb_bi_image_h(mrb_state *mrb, mrb_value self)
{
  SDL_Surface* img = DATA_PTR(self);
  return mrb_fixnum_value(img->h);
}

static mrb_value mrb_bi_image_blit(mrb_state *mrb, mrb_value self)
{
  mrb_value src_obj;
  mrb_int x,y;
  mrb_get_args(mrb, "oii", &src_obj,&x,&y);
  SDL_Surface* dst = DATA_PTR(self);
  SDL_Surface* src = DATA_PTR(src_obj);
  SDL_Rect drect = {x,y,src->w,src->h};
  SDL_BlitSurface(src,NULL,dst,&drect);
  return self;
}

static mrb_value mrb_bi_image_save(mrb_state *mrb, mrb_value self)
{
  const char* path;
  mrb_get_args(mrb, "z", &path);
  SDL_Surface* img = DATA_PTR(self);
  IMG_SavePNG(img,path);
  return self;
}

static void mrb_mruby_bi_image_gem_init(mrb_state* mrb)
{
  struct RClass *image = mrb_define_class(mrb, "Image", mrb->object_class);
  MRB_SET_INSTANCE_TT(image, MRB_TT_DATA);
  mrb_define_class_method(mrb, image, "read", mrb_bi_image_read, MRB_ARGS_REQ(1) ); // path
  mrb_define_method(mrb, image, "initialize", mrb_bi_image_initialize, MRB_ARGS_REQ(2) ); // w,h
  mrb_define_method(mrb, image, "w", mrb_bi_image_w, MRB_ARGS_NONE() );
  mrb_define_method(mrb, image, "h", mrb_bi_image_h, MRB_ARGS_NONE() );
  mrb_define_method(mrb, image, "blit!", mrb_bi_image_blit, MRB_ARGS_REQ(3) ); // Image,x,y
  mrb_define_method(mrb, image, "save", mrb_bi_image_save, MRB_ARGS_REQ(1) ); // path
}

int main(int argc, char* argv[])
{
  mrb_state *mrb = mrb_open();
  mrb_mruby_bi_image_gem_init(mrb);
  // ARGV
  mrb_value ARGV = mrb_ary_new(mrb);
  if(argc>1){
    for (int i = 1; i < argc; i++) {
      mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, argv[i]));
    }
  }
  mrb_define_global_const(mrb, "ARGV", ARGV);
  // Run
  mrb_value obj = mrb_load_irep(mrb,code);
  if (mrb->exc) {
    printf("exception:\n");
    if (mrb_undef_p(obj)) {
      mrb_p(mrb, mrb_obj_value(mrb->exc));
    } else {
      mrb_print_error(mrb);
    }
  }
  return 0;
}
