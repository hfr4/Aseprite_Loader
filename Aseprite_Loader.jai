// Aseprite File Format (.ase/.aseprite) Specifications : https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

Aseprite_File :: struct {
    header : Aseprite_File_Header;
    frames : [..] Frame;
    layers : [..] Layer;
    tags   : [..] Tag;
}

Aseprite_File_Header :: struct {
    file_size   : u32;
    magic       : u16;
    frame_count : u16;
    w, h        : u16;
    color_depth : Aseprite_File_Header_Color_Depth;
    flags       : Aseprite_File_Header_Flags;
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
    frame_size      : u32;
    magic           : u16;
    chunk_count_old : u16;
    frame_duration  : u16;
    chunk_count_new : u32;
}

Cel :: struct {
    kind        : Cel_Kind;
    layer_index : u16;
    x, y        : s16;
    w, h        : u16;
    opacity     : u8;
    userdata    : Userdata;
    pixels      : [..] Color;
}

Cel_Kind :: enum u16 {
    RAW_IMAGE_DATA     :: 0;
    LINKED_CEL         :: 1;
    COMPRESSED_IMAGE   :: 2;
    COMPRESSED_TILEMAP :: 3;
}

Layer :: struct {
    kind        : Layer_Kind;
    flags       : Layer_Flags;
    child_level : u16;
    blend_mode  : Layer_Blend_Mode;
    opacity     : u8;
    name        : string;
    userdata    : Userdata;
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

Tag :: struct {
    name           : string;
    loop_direction : Tag_Loop_Directions;
    repeat_count   : u16;
    from, to       : u16;
    userdata       : Userdata;
}

Tag_Loop_Directions :: enum {
    FORWARD  :: 0;
    REVERSE  :: 1;
    PINGPONG :: 2;
}

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

Color :: struct {
    r, g, b, a : u8;
}

load_aseprite_file :: (using aseprite: *Aseprite_File, filepath: string) -> bool {
    file, success := read_entire_file(filepath);
    if !success {
        print("Failed to load file %.\n", filepath);
        return false;
    }
    defer free(file);

    ReinitializeReader();

    FILE_MAGIC_NUMBER :: 0xA5E0;

    header.file_size    = Eat(u32);
    header.magic        = Eat(u16);
    assert(header.magic == FILE_MAGIC_NUMBER, "Bad file magic number, expected % got %.", FILE_MAGIC_NUMBER, header.magic);
    header.frame_count  = Eat(u16);
    header.w            = Eat(u16);
    header.h            = Eat(u16);
    header.color_depth  = Eat(Aseprite_File_Header_Color_Depth);
    header.flags        = Eat(Aseprite_File_Header_Flags);

    Skip(110);

    for i: 0..header.frame_count - 1 {
        frame: Frame;

        FRAME_MAGIC_NUMBER :: 0xF1FA;

        frame.header.frame_size      = Eat(u32);
        frame.header.magic           = Eat(u16);
        assert(frame.header.magic == FRAME_MAGIC_NUMBER, "Bad file magic number, expected % got %.", FRAME_MAGIC_NUMBER, frame.header.magic);
        frame.header.chunk_count_old = Eat(u16);
        frame.header.frame_duration  = Eat(u16);
        Skip(2);
        frame.header.chunk_count_new = Eat(u32);

        chunk_count := 0;
        if      frame.header.chunk_count_new != 0      chunk_count = frame.header.chunk_count_new;
        else if frame.header.chunk_count_old != 0xFFFF chunk_count = frame.header.chunk_count_old;

        previous_chunk_kind: Chunk_Kind;

        for 0..chunk_count - 1 {
            chunk_start := context.aseprite_reader.cursor;
            chunk_size  := Eat(u32);
            chunk_end   := chunk_start + chunk_size;
            chunk_kind  := Eat(Chunk_Kind);

            if chunk_kind == {
                case .CEL;      DecodeCel();
                case .LAYER;    DecodeLayer();
                case .TAGS;     DecodeTags();
                case .USERDATA; DecodeUserdata();
                case;           Skip(chunk_end - context.aseprite_reader.cursor);
            }

            previous_chunk_kind = chunk_kind;

            assert(context.aseprite_reader.cursor == chunk_end, "Chunk % reading error, we are at %, but should be at %.", chunk_kind, context.aseprite_reader.cursor, chunk_end);
        }

        array_add(*frames, frame);
    }

    return true;
}

deinit :: (using aseprite: *Aseprite_File) {
    for frames {
        for it.cels array_free(it.pixels);
        array_free(it.cels);
    }
    array_free(frames);
    array_free(layers);
    array_free(tags);
}

#scope_file

DecodeCel :: () #expand {
    cel: Cel;

    cel.layer_index = Eat(u16);
    cel.x           = Eat(s16);
    cel.y           = Eat(s16);
    cel.opacity     = Eat(u8);
    cel.kind        = Eat(Cel_Kind);
    Skip(7);
    cel.w           = Eat(u16);
    cel.h           = Eat(u16);

    encoded_count := `chunk_end - context.aseprite_reader.cursor;
    decoded_count := cast(int) cel.w * cast(int) cel.h;

    color_depth := `header.color_depth;

    if      cel.kind == .RAW_IMAGE_DATA    EatPixelsRaw(decoded_count);
    else if cel.kind == .COMPRESSED_IMAGE  EatPixelsCompressed(encoded_count, decoded_count);
    else assert(false, "Cel kind % not supported.", cel.kind);

    array_add(*`frame.cels, cel);
}

DecodeLayer :: () #expand {
    layer: Layer;

    layer.flags       = Eat(Layer_Flags);
    layer.kind        = Eat(Layer_Kind);
    layer.child_level = Eat(u16);
    Skip(4);
    layer.blend_mode  = Eat(Layer_Blend_Mode);
    layer.opacity     = Eat(u8);
    Skip(3);
    layer.name        = Eat(Eat(u16));

    if layer.kind == .TILEMAP {
        Skip(4);
        print("WARNING: Tileset type aseprite layers not supported.\n");
    }

    array_add(*`layers, layer);
}

DecodeTags :: () #expand {
    tag_count := Eat(u16);
    Skip(8);

    for 0..tag_count - 1 {
        tag: Tag;

        tag.from           = Eat(u16);
        tag.to             = Eat(u16);
        tag.loop_direction = Eat(Tag_Loop_Directions);
        tag.repeat_count   = Eat(u16);
        Skip(10);
        tag.name           = Eat(Eat(u16));

        array_add(*`tags, tag);
    }
}

DecodeUserdata :: () #expand {
    userdata: Userdata;

    userdata.flags = Eat(Userdata_Flags);

    if userdata.flags & .HAS_TEXT {
        userdata.text = Eat(Eat(u16));
    }

    if userdata.flags & .HAS_COLOR {
        userdata.color = .{ Eat(u8), Eat(u8), Eat(u8), Eat(u8) };
    }

    if userdata.flags & .HAS_PROPERTIES {
    }

    if `previous_chunk_kind == {
        case .CEL;   print("Cel user data found\n");
        case .LAYER; print("Layer user data found\n");
        case .TAGS;  print("Tag user data found\n");
    }
}

Aseprite_Reader :: struct {
    cursor: int;
    buffer: string;
}

#add_context aseprite_reader: Aseprite_Reader;

ReinitializeReader :: () #expand {
    context.aseprite_reader.cursor = 0;
    context.aseprite_reader.buffer = `file;
}

Skip :: (count: int) #expand {
    context.aseprite_reader.cursor += count;
}

Eat :: (count: int) -> string #expand {
    defer context.aseprite_reader.cursor += count;
    return slice(context.aseprite_reader.buffer, context.aseprite_reader.cursor, count);
}

Eat :: ($T: Type) -> T #expand {
    return (cast(*T) Eat(size_of(T)).data).*;
}

EatPixelsRaw :: (decoded_count: int) #expand {
    if `color_depth == {
        case .RGBA;
            for 0..decoded_count - 1 {
                array_add(*`cel.pixels, .{ Eat(u8), Eat(u8), Eat(u8), Eat(u8) });
            }

        case .GRAYSCALE;
            value := Eat(u8);
            for 0..decoded_count - 1 {
                array_add(*`cel.pixels, .{ value, value, value, Eat(u8) });
            }

        case .INDEXED;
            assert(false, "Indexed mode not supported.");
    }
}

EatPixelsCompressed :: (encoded_count: int, decoded_count: int) #expand {
    stbi :: #import "stb_image";

    if `color_depth == {
        case .RGBA;
            encoded := Eat(encoded_count);
            decoded := alloc_string(decoded_count * 4);
            defer free(decoded);

            decoded_size := stbi.stbi_zlib_decode_buffer(decoded.data, xx decoded.count, encoded.data, xx encoded.count);
            assert(decoded.count == decoded_size, "Failed to decode zlib buffer.");

            for 0..decoded.count / 4 - 1 {
                array_add(*`cel.pixels, .{ decoded.data[it*4], decoded.data[it*4 + 1], decoded.data[it*4 + 2], decoded.data[it*4 + 3] });
            }

        case .GRAYSCALE;
            encoded := Eat(encoded_count);
            decoded := alloc_string(decoded_count * 2);
            defer free(decoded);

            decoded_size := stbi.stbi_zlib_decode_buffer(decoded.data, xx decoded.count, encoded.data, xx encoded.count);
            assert(decoded.count == decoded_size, "Failed to decode zlib buffer.");

            for 0..decoded.count / 2 - 1 {
                array_add(*`cel.pixels, .{ decoded.data[it*2], decoded.data[it*2], decoded.data[it*2], decoded.data[it*2 + 1] });
            }

        case .INDEXED;
            assert(false, "Indexed mode not supported.");
    }
}

#import "String";
#import "Basic";
#import "File";