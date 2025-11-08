// Specs : https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

Aseprite_File :: struct {
    header : Aseprite_File_Header;
    frames : [..] Frame;
    layers : [..] Layer;
    tags   : [..] Tag;
}

Aseprite_File_Header :: struct {
    fileSize   : u32;
    frameCount : u16;
    width      : u16;
    height     : u16;
    colorDepth : u16;
    flags      : Aseprite_File_Header_Flags;
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
    frameSize     : u32;
    chunkCountOld : u16;
    frameDuration : u16;
    chunkCountNew : u32;
}

Cel :: struct {
    kind       : Cel_Kind;
    layerIndex : u16;
    x          : s16;
    y          : s16;
    w          : u16;
    h          : u16;
    opacity    : u8;
    userdata   : Userdata;
    pixels     : [..] Color;
}

Cel_Kind :: enum u16 {
    RAW_IMAGE_DATA     :: 0;
    LINKED_CEL         :: 1;
    COMPRESSED_IMAGE   :: 2;
    COMPRESSED_TILEMAP :: 3;
}

Layer :: struct {
    kind       : Layer_Kind;
    flags      : Layer_Flags;
    childLevel : u16;
    blendMode  : Layer_Blend_Mode;
    opacity    : u8;
    name       : string;
    userdata   : Userdata;
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

Tag ::struct {
    name          : string;
    loopDirection : Tag_Loop_Directions;
    repeatCount   : u16;
    from          : u16;
    to            : u16;
    userdata      : Userdata;
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
    r, g, b, a: u8;
}

load_aseprite_file :: (using aseprite: *Aseprite_File, filepath: string) -> bool {
    file, success := read_entire_file(filepath);
    if !success {
        print("Failed to load file %.\n", filepath);
        return false;
    }

    defer free(file);

    ReinitializeReader();

    header.fileSize    = Eat(u32);

    magic_number := Eat(u16);
    FILE_MAGIC_NUMBER :: 0xA5E0;
    assert(magic_number == FILE_MAGIC_NUMBER, "Bad file magic number, expected % got %.", FILE_MAGIC_NUMBER, magic_number);

    header.frameCount  = Eat(u16);
    header.width       = Eat(u16);
    header.height      = Eat(u16);
    header.colorDepth  = Eat(u16);
    assert(header.colorDepth == 32, "Grayscale and Index modes are not supported.");
    header.flags       = Eat(Aseprite_File_Header_Flags);

    Skip(110);

    for i: 0..header.frameCount - 1 {
        frame: Frame;

        frame.header.frameSize     = Eat(u32);

        magic_number := Eat(u16);
        FRAME_MAGIC_NUMBER :: 0xF1FA;
        assert(magic_number == FRAME_MAGIC_NUMBER, "Bad file magic number, expected % got %.", FRAME_MAGIC_NUMBER, magic_number);

        frame.header.chunkCountOld = Eat(u16);
        frame.header.frameDuration = Eat(u16);
        Skip(2);
        frame.header.chunkCountNew = Eat(u32);

        chunk_count := 0;
        if      frame.header.chunkCountNew != 0      chunk_count = frame.header.chunkCountNew;
        else if frame.header.chunkCountOld != 0xFFFF chunk_count = frame.header.chunkCountOld;

        last_chunk: Chunk_Kind;
        for 0..chunk_count - 1 {
            chunk_start := context.aseprite_reader.cursor;
            chunk_size  := Eat(u32);
            chunk_end   := chunk_start + chunk_size;
            chunk_kind  := Eat(Chunk_Kind);

            if chunk_kind == {
                case .CEL;      DecodeCelChunk();
                case .LAYER;    DecodeLayerChunk();
                case .TAGS;     DecodeTagsChunk();
                case .USERDATA; DecodeUserDataChunk();
                case;           Skip(chunk_end - context.aseprite_reader.cursor);
            }

            last_chunk = chunk_kind;

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

DecodeCelChunk :: () #expand {
    cel: Cel;

    cel.layerIndex = Eat(u16);
    cel.x          = Eat(s16);
    cel.y          = Eat(s16);
    cel.opacity    = Eat(u8);
    cel.kind       = Eat(Cel_Kind);
    assert(cel.kind == .RAW_IMAGE_DATA || cel.kind == .COMPRESSED_IMAGE, "Cel kind % not supported.", cel.kind);
    Skip(7);
    cel.w          = Eat(u16);
    cel.h          = Eat(u16);

    encoded_count := `chunk_end - context.aseprite_reader.cursor;
    decoded_count := cast(int) cel.w * cast(int) cel.h;

    array_reserve(*cel.pixels, decoded_count);
    if      cel.kind == .RAW_IMAGE_DATA    EatPixelsRaw(decoded_count);
    else if cel.kind == .COMPRESSED_IMAGE  EatPixelsZlib(encoded_count, decoded_count);

    array_add(*`frame.cels, cel);
}

DecodeLayerChunk :: () #expand {
    layer: Layer;

    layer.flags      = Eat(Layer_Flags);
    layer.kind       = Eat(Layer_Kind);
    layer.childLevel = Eat(u16);
    Skip(4);
    layer.blendMode  = Eat(Layer_Blend_Mode);
    layer.opacity    = Eat(u8);
    Skip(3);
    length := Eat(u16);
    layer.name       = EatString(length);

    if layer.kind == .TILEMAP {
        Skip(4);
        print("WARNING: Tileset type aseprite layers not supported.\n");
    }

    array_add(*`layers, layer);
}

DecodeTagsChunk :: () #expand {
    tag_count := Eat(u16);
    Skip(8);

    for 0..tag_count - 1 {
        tag: Tag;

        tag.from             = Eat(u16);
        tag.to               = Eat(u16);
        tag.loopDirection    = Eat(Tag_Loop_Directions);
        tag.repeatCount      = Eat(u16);
        Skip(6);
        tag.userdata.color.r = Eat(u8);           // Deprecated ?
        tag.userdata.color.g = Eat(u8);           // Deprecated ?
        tag.userdata.color.b = Eat(u8);           // Deprecated ?
        tag.userdata.color.a = 255;               // Deprecated ?
        Skip(1);
        length := Eat(u16);
        tag.name             = EatString(length); // Deprecated ?

        array_add(*`tags, tag);
    }
}

DecodeUserDataChunk :: () #expand {
    userdata: Userdata;

    userdata.flags = Eat(Userdata_Flags);

    if userdata.flags & .HAS_TEXT {
        length := Eat(u16);
        userdata.text = EatString(length);
    }

    if userdata.flags & .HAS_COLOR {
        userdata.color = .{ Eat(u8), Eat(u8), Eat(u8), Eat(u8) };
    }

    if userdata.flags & .HAS_PROPERTIES {
    }

    if `last_chunk == {
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
    free(context.aseprite_reader.buffer);
    context.aseprite_reader.cursor = 0;
    context.aseprite_reader.buffer = `file;
}

Skip :: (count: int) #expand {
    context.aseprite_reader.cursor += count;
}

Eat :: ($T: Type) -> T #expand {
    defer context.aseprite_reader.cursor += size_of(T);
    return (cast(*T) slice(context.aseprite_reader.buffer, context.aseprite_reader.cursor, size_of(T)).data).*;
}

EatString :: (count: int) -> string #expand {
    defer context.aseprite_reader.cursor += count;
    return slice(context.aseprite_reader.buffer, context.aseprite_reader.cursor, count);
}

EatPixelsRaw :: (decoded_count: int) #expand {
    for 0..decoded_count - 1 {
        array_add(*`cel.pixels, .{ Eat(u8), Eat(u8), Eat(u8), Eat(u8) });
    }
}

EatPixelsZlib :: (encoded_count: int, decoded_count: int) #expand {
    encoded := EatString(encoded_count);
    decoded := alloc_string(decoded_count * 4);

    defer free(decoded);

    stbi :: #import "stb_image";
    decoded_size := stbi.stbi_zlib_decode_buffer(decoded.data, xx decoded.count, encoded.data, xx encoded.count);

    assert(decoded.count == decoded_size, "Failed to decode zlib buffer.");

    pixels_count := decoded.count / 4;
    for 0..pixels_count - 1 {
        array_add(*`cel.pixels, .{ decoded.data[it*4], decoded.data[it*4 + 1], decoded.data[it*4 + 2], decoded.data[it*4 + 3] });
    }
}

#import "String";
#import "Basic";
#import "File";