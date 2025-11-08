main :: () {
    w := Window.create_window(800, 600, "Aseprite Loader");
    Simp.set_render_target(w);

    animation := LoadAnimation("bad_apple.aseprite");

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

        Update(*animation, xx dt);

        {
            Simp.set_render_target(w);
            Simp.clear_render_target(0.2, 0.2, 0.2, 1);

            DrawAnimationCentered(*animation, .{ 400, 300 });

            Simp.swap_buffers(w);
        }

        reset_temporary_storage();
        sleep_milliseconds(10);
    }
}

#load "animation.jai";

Aseprite :: #import,file "../Aseprite_Loader.jai";

GL     :: #import "GL";
Window :: #import "Window_Creation";
Simp   :: #import "Simp";
Input  :: #import "Input";

#import "Math";
#import "Basic";