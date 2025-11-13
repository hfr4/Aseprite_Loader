main :: () {
    w := Window.create_window(1200, 900, "Aseprite Loader");
    Simp.set_render_target(w);

    tilesets: [..] Simp.Texture;

    LoadTilesets();

    animation_rgba       := LoadAnimation("bad_apple_rgba.aseprite");
    animation_grayscale  := LoadAnimation("bad_apple_grayscale.aseprite");
    animation_indexed    := LoadAnimation("bad_apple_indexed.aseprite");
    animation_userdata   := LoadAnimation("bad_apple_userdata.aseprite");
    animation_slice      := LoadAnimation("bad_apple_slice.aseprite");

    before := seconds_since_init();

    quit := false;
    while !quit {
        now := seconds_since_init();
        dt := now - before;
        before = now;

        Input.update_window_events();

        for Input.get_window_resizes() {
            Simp.update_window(it.window);
        }

        for Input.events_this_frame {
            if it.type == .QUIT quit = true;
        }

        Update(*animation_rgba      , xx dt);
        Update(*animation_grayscale , xx dt);
        Update(*animation_indexed   , xx dt);
        Update(*animation_userdata  , xx dt);
        Update(*animation_slice     , xx dt);

        {
            Simp.set_render_target(w);
            Simp.clear_render_target(0.2, 0.2, 0.2, 1);

            DrawAnimationCentered(*animation_rgba      , .{ 200 , 450 });
            DrawAnimationCentered(*animation_grayscale , .{ 600 , 450 });
            DrawAnimationCentered(*animation_indexed   , .{ 1000, 450 });
            DrawAnimationCentered(*animation_userdata  , .{ 200 , 200 });
            DrawAnimationCentered(*animation_slice     , .{ 600 , 200 });

            for tilesets {
                DrawTextureCentered(it, .{ 100 + 100.0 * it_index, 800 }, scale = 6);
            }

            Simp.swap_buffers(w);
        }

        reset_temporary_storage();
        sleep_milliseconds(10);
    }
}

#load "animation.jai";

Aseprite :: #import,file "../module.jai";

GL       :: #import "GL";
Window   :: #import "Window_Creation";
Simp     :: #import "Simp";
Input    :: #import "Input";

#import "Math";
#import "Basic";


LoadTilesets :: () #expand {
    aseprite : Aseprite.Aseprite_Animation;
    loaded := Aseprite.aseprite_load(*aseprite, "tilemap_rgba.aseprite");
    assert(loaded);

    for aseprite.tilesets {
        bitmap: Simp.Bitmap;

        Simp.bitmap_alloc(*bitmap, xx it.tile_w, xx (cast(int) it.tile_h * cast(int) it.tiles_count), .RGBA8);
        defer Simp.deinit(*bitmap);

        for * bitmap.data  it.* = 0;

        for it.pixels {
            bitmap.data[it_index * 4 +0] = it.r;
            bitmap.data[it_index * 4 +1] = it.g;
            bitmap.data[it_index * 4 +2] = it.b;
            bitmap.data[it_index * 4 +3] = it.a;
        }

        tileset := array_add(*`tilesets);

        loaded := Simp.texture_load_from_bitmap(tileset, *bitmap);
        assert(loaded);

        GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
        GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
    }
}