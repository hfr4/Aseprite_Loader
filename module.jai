// File format specifications :
// https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

Aseprite_File :: struct {
    header         : Aseprite_File_Header;
    palette        : Palette;
    color_profile  : Color_Profile;
    frames         : [..] Frame;
    layers         : [..] Layer;
    slices         : [..] Slice;
    tilesets       : [..] Tileset;
    tags           : [..] Tag;
    external_files : [..] External_File;
    buffer         : string;
}

Aseprite_File_Header :: struct {
    frame_count               : u16;
    w, h                      : u16;
    color_depth               : Aseprite_File_Header_Color_Depth;
    flags                     : Aseprite_File_Header_Flags;
    transparent_palette_index : u8;
    global_frame_duration     : u16;
    number_of_colors          : u16;
    pixel_w, pixel_h          : u8;
    grid_x, grid_y            : s16;
    grid_w, grid_h            : u16;
}

Aseprite_File_Header_Color_Depth :: enum u16 {
    INDEXED   :: 8;
    GRAYSCALE :: 16;
    RGBA      :: 32;
}

Aseprite_File_Header_Flags :: enum_flags u32 {
    LAYER_OPACITY_HAS_VALID_VALUE                    :: 1;
    LAYER_BLEND_MODE_AND_OPACITY_IS_VALID_FOR_GROUPS :: 2;
    LAYERS_HAVE_UUID                                 :: 4;
}

Frame :: struct {
    header : Frame_Header;
    cels   : [..] Cel;
}

Frame_Header :: struct {
    frame_duration : u16;
    chunk_count    : u32;
}

Cel :: struct {
    kind        : Cel_Kind;
    layer_index : u16;
    z_index     : s16;
    x, y        : s16;
    w, h        : u16;
    opacity     : u8;
    userdata    : Userdata;
    pixels      : [] Color;
    extra       : Cel_Extra;
}

Cel_Kind :: enum u16 {
    RAW_IMAGE_DATA     :: 0;
    LINKED_CEL         :: 1;
    COMPRESSED_IMAGE   :: 2;
    COMPRESSED_TILEMAP :: 3;
}

Cel_Extra :: struct {
    flags            : Cel_Extra_Flags;
    precise_bounds_x : u32;
    precise_bounds_y : u32;
    precise_bounds_w : u32;
    precise_bounds_h : u32;
}

Cel_Extra_Flags :: enum u32 {
    HAS_PRECISE_BOUNDS :: 1;
}

Layer :: struct {
    kind          : Layer_Kind;
    flags         : Layer_Flags;
    child_level   : u16;
    blend_mode    : Layer_Blend_Mode;
    opacity       : u8;
    name          : string;
    userdata      : Userdata;
    tileset_index : u32;
    uuid          : UUID;
}

Layer_Kind :: enum u16 {
    NORMAL  :: 0;
    GROUP   :: 1;
    TILEMAP :: 2;
}

Layer_Flags :: enum_flags u16 {
    VISIBLE            :: 1;
    EDITABLE           :: 2;
    LOCK_MOVEMENT      :: 4;
    BACKGROUND         :: 8;
    PREFER_LINKED_CELS :: 16;
    COLLAPSED          :: 32;
    REFERENCE          :: 64;
}

// Blend functions :
// https://github.com/aseprite/aseprite/blob/master/src/doc/blend_funcs.cpp

Layer_Blend_Mode :: enum u16 {
    NORMAL      :: 0;
    MULTIPLY    :: 1;
    SCREEN      :: 2;
    OVERLAY     :: 3;
    DARKEN      :: 4;
    LIGHTEN     :: 5;
    COLOR_DODGE :: 6;
    COLOR_BURN  :: 7;
    HARD_LIGHT  :: 8;
    SOFT_LIGHT  :: 9;
    DIFFERENCE  :: 10;
    EXCLUSION   :: 11;
    HUE         :: 12;
    SATURATION  :: 13;
    COLOR       :: 14;
    LUMINOSITY  :: 15;
    ADDITION    :: 16;
    SUBTRACT    :: 17;
    DIVIDE      :: 18;
}

Slice :: struct {
    flags              : Slice_Flags;
	name               : string;
	frame_number       : u32;
	origin_x, origin_y : s32;
	w, h               : u32;
	center_x, center_y : s32;
	center_w, center_h : u32;
	pivot_x, pivot_y   : s32;
	userdata           : Userdata;
}

Slice_Flags :: enum_flags u32 {
    IS_9_PATCHES_SLICE    :: 1;
    HAS_PIVOT_INFORMATION :: 2;
}

Tileset :: struct {
    id                       : u32;
    flags                    : Tileset_Flags;
    tiles_count              : u32;
    tile_w, tile_h           : u16;
    base_index               : s16;
    external_file_id         : u32;
    external_file_tileset_id : u32;
    name                     : string;
    pixels                   : [] Color;
}

Tileset_Flags :: enum_flags u32 {
    HAS_LINK_TO_EXTERNAL_FILE      :: 1;
    HAS_TILES_INSIDE_THIS_FILE     :: 2;
    TILE_ID_EQUALS_0_AS_EMPTY_TILE :: 4;
    MATCH_X_FLIPS_IN_AUTO_MODE     :: 8;
    MATCH_Y_FLIPS_IN_AUTO_MODE     :: 16;
    MATCH_D_FLIPS_IN_AUTO_MODE     :: 32;
}

Tag :: struct {
    name           : string;
    loop_direction : Tag_Loop_Direction;
    repeat_count   : u16;
    from, to       : u16;
    userdata       : Userdata;
}

Tag_Loop_Direction :: enum u8 {
    FORWARD          :: 0;
    REVERSE          :: 1;
    PINGPONG         :: 2;
    PINGPONG_REVERSE :: 3;
}

Color_Profile :: struct {
    kind        : Color_Profile_Kind;
    flags       : Color_Profile_Flags;
    fixed_gamma : u32;
    icc_profile : string;
}

Color_Profile_Kind :: enum u16 {
    NONE :: 0;
    SRGB :: 1;
    ICC  :: 2;
}

Color_Profile_Flags :: enum_flags u16 {
    SPECIAL_FIXED_GAMMA :: 1;
}

Palette :: struct {
    colors : [..] Color;
}

Palette_Color_Flags :: enum_flags u16 {
    HAS_NAME :: 1;
}

External_File :: struct {
    id   : u32;
    kind : External_File_Kind;
    name : string;
}

External_File_Kind :: enum u8 {
    EXTERNAL_PALETTE                   :: 0;
    EXTERNAL_TILESET                   :: 1;
    EXTENSION_NAME_FOR_PROPERTIES      :: 2;
    EXTENSION_NAME_FOR_TILE_MANAGEMENT :: 3;
}

Userdata :: struct {
    flags : Userdata_Flags;
    text  : string;
    color : Color;
}

Userdata_Flags :: enum_flags u32 {
    HAS_TEXT       :: 1;
    HAS_COLOR      :: 2;
    HAS_PROPERTIES :: 4;
}

Color :: [4] u8;

UUID :: [16] u8;

Chunk_Kind :: enum u16 {
    OLD_PALETTE_A  :: 0x0004;
    OLD_PALETTE_B  :: 0x0011;
    LAYER          :: 0x2004;
    CEL            :: 0x2005;
    CEL_EXTRA      :: 0x2006;
    COLOR_PROFILE  :: 0x2007;
    EXTERNAL_FILES :: 0x2008;
    MASK           :: 0x2016;
    PATH           :: 0x2017;
    TAGS           :: 0x2018;
    PALETTE        :: 0x2019;
    USERDATA       :: 0x2020;
    SLICE          :: 0x2022;
    TILESET        :: 0x2023;
}

aseprite_load :: (aseprite: *Aseprite_File, filepath: string) -> bool {
    buffer, ok := read_entire_file(filepath);

    if !ok {
        log_error("Failed to load file %.\n", filepath);
        return false;
    }

    aseprite.buffer = buffer;

    r: Aseprite_Reader;
    r.aseprite = aseprite;

    DecodeFileHeader(*r);

    for 0..aseprite.header.frame_count - 1 {
        frame := array_add(*aseprite.frames);

        DecodeFrameHeader(*r);

        for 0..frame.header.chunk_count - 1 {
            chunk_start := r.cursor;
            chunk_size  := Eat(*r, u32);

            r.current_chunk_end = chunk_start + chunk_size;

            chunk_kind := Eat(*r, Chunk_Kind);

            if chunk_kind == {
                case .OLD_PALETTE_A;  DecodeOldPalette(*r);
                case .OLD_PALETTE_B;  DecodeOldPalette(*r);
                case .LAYER;          DecodeLayer(*r);
                case .CEL;            DecodeCel(*r);
                case .CEL_EXTRA;      DecodeCelExtra(*r);
                case .COLOR_PROFILE;  DecodeColorProfile(*r);
                case .EXTERNAL_FILES; DecodeExternalFiles(*r);
                case .TAGS;           DecodeTags(*r);
                case .PALETTE;        DecodeNewPalette(*r);
                case .USERDATA;       DecodeUserdata(*r);
                case .SLICE;          DecodeSlice(*r);
                case .TILESET;        DecodeTileset(*r);
                case;                 Skip(*r, r.current_chunk_end - r.cursor);
            }

            r.previous_chunk_kind = chunk_kind;

            if r.cursor != r.current_chunk_end {
                log_error("Chunk % reading error, we are at %, but should be at %.", chunk_kind, r.cursor, r.current_chunk_end);
                return false;
            }
        }
    }

    return true;
}

deinit :: (using aseprite: *Aseprite_File) {
    for frames {
        for it.cels {
            if it.kind != .LINKED_CEL {
                array_free(it.pixels);
            }
        }
        array_free(it.cels);
    }

    for tilesets {
        array_free(it.pixels);
    }

    array_free(palette.colors);
    array_free(layers);
    array_free(tags);
    array_free(frames);
    array_free(slices);
    array_free(tilesets);
    array_free(external_files);

    free(buffer);
}

#scope_file

Aseprite_Reader :: struct {
    aseprite                  : *Aseprite_File;
    cursor                    : int;
    current_chunk_end         : int;
    previous_chunk_kind       : Chunk_Kind;
    ignore_old_palette_chunks : bool;
}

Skip :: (r: *Aseprite_Reader, count: int) {
    r.cursor += count;
}

Eat :: (r: *Aseprite_Reader, count: int) -> string {
    defer r.cursor += count;
    return slice(r.aseprite.buffer, r.cursor, count);
}

Eat :: (r: *Aseprite_Reader, $T: Type) -> T {
    return (cast(*T) Eat(r, size_of(T)).data).*;
}

DecodeFileHeader :: (r: *Aseprite_Reader) {
    file_size := Eat(r, u32);
    assert(file_size == r.aseprite.buffer.count, "Bad file size");

    magic := Eat(r, u16);
    assert(magic == 0xA5E0, "Bad file magic number");

    r.aseprite.header.frame_count               = Eat(r, u16);
    r.aseprite.header.w                         = Eat(r, u16);
    r.aseprite.header.h                         = Eat(r, u16);
    r.aseprite.header.color_depth               = Eat(r, Aseprite_File_Header_Color_Depth);
    r.aseprite.header.flags                     = Eat(r, Aseprite_File_Header_Flags);
    r.aseprite.header.global_frame_duration     = Eat(r, u16);
    Skip(r, 8);
    r.aseprite.header.transparent_palette_index = Eat(r, u8);
    Skip(r, 3);
    r.aseprite.header.number_of_colors          = Eat(r, u16);
	r.aseprite.header.pixel_w                   = Eat(r, u8);
	r.aseprite.header.pixel_h                   = Eat(r, u8);
	r.aseprite.header.grid_x                    = Eat(r, s16);
	r.aseprite.header.grid_y                    = Eat(r, s16);
	r.aseprite.header.grid_w                    = Eat(r, u16);
	r.aseprite.header.grid_h                    = Eat(r, u16);
    Skip(r, 84);
}

DecodeFrameHeader :: (r: *Aseprite_Reader) {
    frame := *r.aseprite.frames[r.aseprite.frames.count - 1];

    frame_size := Eat(r, u32);

    magic := Eat(r, u16);
    assert(magic == 0xF1FA, "Bad frame magic number");

    old_chunk_count := Eat(r, u16);
    frame_duration  := Eat(r, u16);
    Skip(r, 2);
    new_chunk_count := Eat(r, u32);

    if frame_duration > 0              frame.header.frame_duration = frame_duration;
    else                               frame.header.frame_duration = r.aseprite.header.global_frame_duration;

    if      new_chunk_count != 0x0000  frame.header.chunk_count = new_chunk_count;
    else if old_chunk_count != 0xFFFF  frame.header.chunk_count = old_chunk_count;
}

DecodeCel :: (r: *Aseprite_Reader) {
    frame := *r.aseprite.frames[r.aseprite.frames.count - 1];

    cel := array_add(*frame.cels);

    cel.layer_index = Eat(r, u16);
    cel.x           = Eat(r, s16);
    cel.y           = Eat(r, s16);
    cel.opacity     = Eat(r, u8);
    cel.kind        = Eat(r, Cel_Kind);
    cel.z_index     = Eat(r, s16);
    Skip(r, 5);

    if cel.kind == {
        case .RAW_IMAGE_DATA;
            cel.w = Eat(r, u16);
            cel.h = Eat(r, u16);

            pixels_count := cast(int) cel.w * cast(int) cel.h;
            cel.pixels = NewArray(pixels_count, Color);

            if r.aseprite.header.color_depth == {
                case .RGBA;
                    for * cel.pixels {
                        it.* = Eat(r, Color);
                    }

                case .GRAYSCALE;
                    value := Eat(r, u8);
                    for * cel.pixels {
                        it.* = .[ value, value, value, Eat(r, u8) ];
                    }

                case .INDEXED;
                    palette_index := Eat(r, u8);
                    for * cel.pixels {
                        if palette_index != r.aseprite.header.transparent_palette_index {
                            it.* = r.aseprite.palette.colors[ palette_index ];
                        }
                    }
            }

        case .LINKED_CEL;
            linked_frame_index := Eat(r, u16);

            linked_frame := *r.aseprite.frames[linked_frame_index];
            linked_cel   := *linked_frame.cels[cel.layer_index];

            cel.w      = linked_cel.w;
            cel.h      = linked_cel.h;
            cel.pixels = linked_cel.pixels;

        case .COMPRESSED_IMAGE;
            cel.w = Eat(r, u16);
            cel.h = Eat(r, u16);

            bytes_per_color := cast(int) r.aseprite.header.color_depth / 8;

            encoded_count := r.current_chunk_end - r.cursor;
            encoded       := Eat(r, encoded_count);

            decoded_count := cast(int) cel.w * cast(int) cel.h * bytes_per_color;
            decoded       := alloc_string(decoded_count);

            defer free(decoded);

            decoded_size := stbi_zlib_decode_buffer(decoded.data, xx decoded.count, encoded.data, xx encoded.count);
            assert(decoded.count == decoded_size, "Failed to decode zlib buffer.");

            pixels_count := decoded.count / bytes_per_color;
            cel.pixels = NewArray(pixels_count, Color);

            if r.aseprite.header.color_depth == {
                case .RGBA;
                    for * cel.pixels {
                        it.* = .[ decoded.data[it_index*4], decoded.data[it_index*4+1], decoded.data[it_index*4+2], decoded.data[it_index*4+3] ];
                    }

                case .GRAYSCALE;
                    for * cel.pixels {
                        it.* = .[ decoded.data[it_index*2], decoded.data[it_index*2], decoded.data[it_index*2], decoded.data[it_index*2+1] ];
                    }

                case .INDEXED;
                    for * cel.pixels {
                        palette_index := decoded.data[it_index];
                        if palette_index != r.aseprite.header.transparent_palette_index {
                            it.* = r.aseprite.palette.colors[ palette_index ];
                        }
                    }
            }

        case .COMPRESSED_TILEMAP;
            layer   := *r.aseprite.layers[cel.layer_index];
            tileset := *r.aseprite.tilesets[layer.tileset_index];

            tilemap_tiles_count_w := Eat(r, u16);
            tilemap_tiles_count_h := Eat(r, u16);

            cel.w = tilemap_tiles_count_w * tileset.tile_w;
            cel.h = tilemap_tiles_count_h * tileset.tile_h;

            bits_per_tile := Eat(r, u16);

            bitmask_tile_id := Eat(r, u32);
            bitmask_x_flip  := Eat(r, u32);
            bitmask_y_flip  := Eat(r, u32);
            bitmask_d_flip  := Eat(r, u32);
            Skip(r, 10);

            bytes_per_tile := bits_per_tile / 8;

            encoded_count := r.current_chunk_end - r.cursor;
            encoded       := Eat(r, encoded_count);

            decoded_count := cast(int) tilemap_tiles_count_w * cast(int) tilemap_tiles_count_h * bytes_per_tile;
            decoded       := alloc_string(decoded_count);

            decoded_size := stbi_zlib_decode_buffer(decoded.data, xx decoded.count, encoded.data, xx encoded.count);
            assert(decoded.count == decoded_size, "Failed to decode zlib buffer.");

            defer free(decoded);

            tiles_count := decoded.count / bytes_per_tile;

            pixels_count := cast(int) tileset.tile_w * cast(int) tileset.tile_h * tiles_count;
            cel.pixels = NewArray(pixels_count, Color);

            for 0..tiles_count - 1 {
                a := cast(u32) decoded.data[it*4+0];
                b := cast(u32) decoded.data[it*4+1];
                c := cast(u32) decoded.data[it*4+2];
                d := cast(u32) decoded.data[it*4+3];

                bits := a + (b << 8) + (c << 16) + (d << 24);

                x_flip  := (bits & bitmask_x_flip) == bitmask_x_flip;
                y_flip  := (bits & bitmask_y_flip) == bitmask_y_flip;
                d_flip  := (bits & bitmask_d_flip) == bitmask_d_flip;

                tile_id := (bits & bitmask_tile_id);
                tileset_offset := cast(int) tileset.tile_w * cast(int) tileset.tile_h * cast(int) tile_id;

                tilemap_x := (it % tilemap_tiles_count_w) * tileset.tile_w;
                tilemap_y := (it / tilemap_tiles_count_w) * tileset.tile_h;
                tilemap_offset := tilemap_x + tilemap_y * tileset.tile_w * tilemap_tiles_count_w;

                for x : 0..tileset.tile_w - 1 {
                    for y : 0..tileset.tile_h - 1 {
                        dx, dy := x, y;

                        if x_flip  dx = tileset.tile_w - 1 - x;
                        if y_flip  dy = tileset.tile_h - 1 - y;
                        if d_flip  swap(*dx, *dy);

                        i := dx + dy * tileset.tile_w;
                        j := x  + y  * tileset.tile_w * tilemap_tiles_count_w;

                        cel.pixels[tilemap_offset + j] = tileset.pixels[tileset_offset + i];
                    }
                }
            }
    }
}

DecodeCelExtra :: (r: *Aseprite_Reader) {
    assert(r.previous_chunk_kind == .CEL);

    frame := *r.aseprite.frames[r.aseprite.frames.count - 1];
    cel   := *frame.cels[frame.cels.count - 1];

    cel.extra.flags = Eat(r, Cel_Extra_Flags);

    if cel.extra.flags & .HAS_PRECISE_BOUNDS {
        cel.extra.precise_bounds_x = Eat(r, u32);
        cel.extra.precise_bounds_y = Eat(r, u32);
        cel.extra.precise_bounds_w = Eat(r, u32);
        cel.extra.precise_bounds_h = Eat(r, u32);
    }
}

DecodeLayer :: (r: *Aseprite_Reader) {
    layer := array_add(*r.aseprite.layers);

    layer.flags       = Eat(r, Layer_Flags);
    layer.kind        = Eat(r, Layer_Kind);
    layer.child_level = Eat(r, u16);
    Skip(r, 4);
    layer.blend_mode  = Eat(r, Layer_Blend_Mode);
    layer.opacity     = Eat(r, u8);
    Skip(r, 3);
    layer.name        = Eat(r, Eat(r, u16));

    if layer.kind == .TILEMAP {
        layer.tileset_index = Eat(r, u32);
    }

    if r.aseprite.header.flags & .LAYERS_HAVE_UUID {
        layer.uuid = Eat(r, UUID);
    }
}

DecodeExternalFiles :: (r: *Aseprite_Reader) {
    files_count := Eat(r, u32);
    Skip(r, 8);

    for 0..files_count - 1 {
        file := array_add(*r.aseprite.external_files);

        file.id   = Eat(r, u32);
        file.kind = Eat(r, External_File_Kind);
        Skip(r, 7);
        file.name = Eat(r, Eat(r, u16));
    }
}

DecodeTags :: (r: *Aseprite_Reader) {
    tag_count := Eat(r, u16);
    Skip(r, 8);

    for 0..tag_count - 1 {
        tag := array_add(*r.aseprite.tags);

        tag.from           = Eat(r, u16);
        tag.to             = Eat(r, u16);
        tag.loop_direction = Eat(r, Tag_Loop_Direction);
        tag.repeat_count   = Eat(r, u16);
        Skip(r, 10);
        tag.name           = Eat(r, Eat(r, u16));
    }
}

DecodeUserdata :: (r: *Aseprite_Reader) {
    userdata: Userdata;

    userdata.flags = Eat(r, Userdata_Flags);

    if userdata.flags & .HAS_TEXT {
        userdata.text = Eat(r, Eat(r, u16));
    }

    if userdata.flags & .HAS_COLOR {
        userdata.color = Eat(r, Color);
    }

    if userdata.flags & .HAS_PROPERTIES {
        properties_size      := Eat(r, u32);
        properties_map_count := Eat(r, u32);
        Skip(r, properties_size - 8);
    }

    if r.previous_chunk_kind == {
        case .CEL;
            frame := *r.aseprite.frames[r.aseprite.frames.count - 1];
            frame.cels[frame.cels.count - 1].userdata = userdata;

        case .LAYER;
            r.aseprite.layers[r.aseprite.layers.count - 1].userdata = userdata;

        case .TAGS;
            r.aseprite.tags[r.aseprite.tags.count - 1].userdata = userdata;

        case .SLICE;
            r.aseprite.slices[r.aseprite.slices.count - 1].userdata = userdata;
    }
}

DecodeColorProfile ::  (r: *Aseprite_Reader) {
    r.aseprite.color_profile.kind        = Eat(r, Color_Profile_Kind);
    r.aseprite.color_profile.flags       = Eat(r, Color_Profile_Flags);
    r.aseprite.color_profile.fixed_gamma = Eat(r, u32);
    Skip(r, 8);

    if r.aseprite.color_profile.kind == .ICC {
        r.aseprite.color_profile.icc_profile = Eat(r, Eat(r, u32));
    }
}

DecodeOldPalette :: (r: *Aseprite_Reader) {
    if r.ignore_old_palette_chunks {
        Skip(r, r.current_chunk_end - r.cursor);
    } else {
        packets_count := Eat(r, u16);

        for 0..packets_count - 1 {
            skip_count   := Eat(r, u8);
            colors_count := Eat(r, u8);

            for 0..colors_count - 1 {
                array_add(*r.aseprite.palette.colors, .[ Eat(r, u8), Eat(r, u8), Eat(r, u8), 255 ]);
            }
        }
    }
}

DecodeNewPalette :: (r: *Aseprite_Reader) {
    array_reset(*r.aseprite.palette.colors);

    palette_size := Eat(r, u32);

    from := Eat(r, u32);
    to   := Eat(r, u32);
    Skip(r, 8);

    for from..to {
        flags := Eat(r, Palette_Color_Flags);

        array_add(*r.aseprite.palette.colors, .[ Eat(r, u8), Eat(r, u8), Eat(r, u8), Eat(r, u8) ]);

        if flags & .HAS_NAME {
            name := Eat(r, Eat(r, u16));
        }
    }

    r.ignore_old_palette_chunks = true;
}

DecodeSlice :: (r: *Aseprite_Reader) {
    slice_count := Eat(r, u32);
    slice_flags := Eat(r, Slice_Flags);
    Skip(r, 4);
    slice_name  := Eat(r, Eat(r, u16));

    for 0..slice_count - 1 {
        slice := array_add(*r.aseprite.slices);

        slice.flags        = slice_flags;
        slice.name         = slice_name;
        slice.frame_number = Eat(r, u32);
        slice.origin_x     = Eat(r, s32);
        slice.origin_y     = Eat(r, s32);
        slice.w            = Eat(r, u32);
        slice.h            = Eat(r, u32);

        if slice_flags & .IS_9_PATCHES_SLICE {
            slice.center_x = Eat(r, s32);
            slice.center_y = Eat(r, s32);
            slice.center_w = Eat(r, u32);
            slice.center_h = Eat(r, u32);
        }

        if slice_flags & .HAS_PIVOT_INFORMATION {
            slice.pivot_x = Eat(r, s32);
            slice.pivot_y = Eat(r, s32);
        }
    }
}

DecodeTileset :: (r: *Aseprite_Reader) {
    tileset := array_add(*r.aseprite.tilesets);

    tileset.id          = Eat(r, u32);
    tileset.flags       = Eat(r, Tileset_Flags);
    tileset.tiles_count = Eat(r, u32);
    tileset.tile_w      = Eat(r, u16);
    tileset.tile_h      = Eat(r, u16);
    tileset.base_index  = Eat(r, s16);
    Skip(r, 14);
    tileset.name        = Eat(r, Eat(r, u16));

    if tileset.flags & .HAS_LINK_TO_EXTERNAL_FILE {
        tileset.external_file_id         = Eat(r, u32);
        tileset.external_file_tileset_id = Eat(r, u32);
    }

    if tileset.flags & .HAS_TILES_INSIDE_THIS_FILE {
        bytes_per_color := (cast(int) r.aseprite.header.color_depth / 8);

        encoded_count  := Eat(r, u32);
        encoded        := Eat(r, encoded_count);

        decoded_count  := cast(int) tileset.tile_w * cast(int) tileset.tile_h * cast(int) tileset.tiles_count * bytes_per_color;
        decoded        := alloc_string(decoded_count);

        defer free(decoded);

        decoded_size := stbi_zlib_decode_buffer(decoded.data, xx decoded.count, encoded.data, xx encoded.count);
        assert(decoded.count == decoded_size, "Failed to decode zlib buffer.");

        pixels_count := decoded.count / bytes_per_color;
        tileset.pixels = NewArray(pixels_count, Color);

        if r.aseprite.header.color_depth == {
            case .RGBA;
                for * tileset.pixels {
                    it.* = .[ decoded.data[it_index*4], decoded.data[it_index*4+1], decoded.data[it_index*4+2], decoded.data[it_index*4+3] ];
                }

            case .GRAYSCALE;
                for * tileset.pixels {
                    it.* = .[ decoded.data[it_index*2], decoded.data[it_index*2], decoded.data[it_index*2], decoded.data[it_index*2+1] ];
                }

            case .INDEXED;
                for * tileset.pixels {
                    palette_index := decoded.data[it_index];
                    if palette_index != r.aseprite.header.transparent_palette_index {
                        it.* = r.aseprite.palette.colors[ palette_index ];
                    }
                }
        }
    }
}

#import "stb_image";
#import "String";
#import "Basic";
#import "File";