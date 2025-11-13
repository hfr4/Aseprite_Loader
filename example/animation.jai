Animation :: struct {
    frames  : [..] Frame;
    index   : int;
    elapsed : float;
    play    := true;
    loop    := true;
    reverse := false;
}

Frame :: struct {
    texture:  *Simp.Texture;
    duration: float;
}

LoadAnimation :: (filepath: string) -> Animation {
    aseprite: Aseprite.Aseprite_Animation;

    ok := Aseprite.aseprite_load(*aseprite, filepath);
    assert(ok, "Can't find aseprite file at %", filepath);
    defer Aseprite.deinit(*aseprite);

    for aseprite.layers {
        if it.userdata.flags & .HAS_TEXT  print("text : %\n", it.userdata.text);
        if it.userdata.flags & .HAS_COLOR print("color : % \n", it.userdata.color);
    }

    for aseprite.tags {
        if it.userdata.flags & .HAS_TEXT  print("text : %\n", it.userdata.text);
        if it.userdata.flags & .HAS_COLOR print("color : % \n", it.userdata.color);
    }

    for aseprite.frames for it.cels {
        if it.userdata.flags & .HAS_TEXT  print("text : %\n", it.userdata.text);
        if it.userdata.flags & .HAS_COLOR print("color : % \n", it.userdata.color);
    }

    for aseprite.slices {
        if it.userdata.flags & .HAS_TEXT  print("text : %\n", it.userdata.text);
        if it.userdata.flags & .HAS_COLOR print("color : % \n", it.userdata.color);
    }

    animation: Animation;

    /*

    TODO : NOTE 5. https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

    int order() const {
        return cel.layer_index + cel.z_index;
    }

    */

    for frame : aseprite.frames {
        bitmap: Simp.Bitmap;
        Simp.bitmap_alloc(*bitmap, aseprite.header.w, aseprite.header.h, .RGBA8);
        defer Simp.deinit(*bitmap);

        for * bitmap.data  it.* = 0;

        for cel : frame.cels {
            for pixel : cel.pixels {
                x := cel.x + (it_index % cel.w);
                y := cel.y + (it_index / cel.w);

                i := (x + y * aseprite.header.w) * 4;

                bg := Vector4.{ xx bitmap.data[i+0], xx bitmap.data[i+1], xx bitmap.data[i+2], xx bitmap.data[i+3] };
                fg := Vector4.{ xx pixel.r         , xx pixel.g         , xx pixel.b         , xx pixel.a          };

                blended := BlendAdd(bg / 255.0, fg / 255.0);

                bitmap.data[i+0] = cast(u8) (blended.x * 255);
                bitmap.data[i+1] = cast(u8) (blended.y * 255);
                bitmap.data[i+2] = cast(u8) (blended.z * 255);
                bitmap.data[i+3] = cast(u8) (blended.w * 255);
            }
        }

        anim_frame := array_add(*animation.frames);
        anim_frame.duration = frame.header.frame_duration / 1000.0;
        anim_frame.texture  = New(Simp.Texture);

        loaded := Simp.texture_load_from_bitmap(anim_frame.texture, *bitmap);
        assert(loaded);

        GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
        GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
    }

    return animation;
}

Update :: (using animation: *Animation, dt: float) {
    if play  elapsed += dt;

    while elapsed >= frames[index].duration {
        elapsed -= frames[index].duration;

        if !reverse {
            if index < frames.count - 1 {
                index += 1;
            } else if loop {
                index = 0;
            } else {
                play = false;
            }
        } else {
            if index > 0 {
                index -= 1;
            } else if loop {
                index = frames.count - 1;
            } else {
                play = false;
            }
        }
    }
}

BlendAdd :: (background: Vector4, foreground: Vector4) -> Vector4 {
    br, bg, bb, ba := background.x, background.y, background.z, background.w;
    fr, fg, fb, fa := foreground.x, foreground.y, foreground.z, foreground.w;

    a := fa + ba * (1 - fa);
    r := ifx a != 0.0 then (fr * fa + br * ba * (1 - fa)) / a;
    g := ifx a != 0.0 then (fg * fa + bg * ba * (1 - fa)) / a;
    b := ifx a != 0.0 then (fb * fa + bb * ba * (1 - fa)) / a;

    return .{ r, g, b, a };
}

DrawTextureCentered :: (texture: Simp.Texture, position := Vector2.{ 0, 0 }, scale := 1) {
    w := cast(float) texture.width * scale;
    h := cast(float) texture.height * scale;
    x := position.x;
    y := position.y;

    x0 := x     - w/2;
    y0 := y     - h/2;
    x1 := x + w - w/2;
    y1 := y + h - h/2;

    p0 := Vector2.{ x0, y0 };
    p1 := Vector2.{ x1, y0 };
    p2 := Vector2.{ x1, y1 };
    p3 := Vector2.{ x0, y1 };

    Simp.set_shader_for_images(*texture);
    Simp.immediate_quad(p0, p1, p2, p3, .{ 1, 1, 1, 1 });
}

DrawAnimationCentered :: (using animation: Animation, position := Vector2.{ 0, 0 }, scale := 1) {
	DrawTextureCentered(frames[index].texture, position, scale);
}