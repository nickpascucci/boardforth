# BoardForth

BoardForth is an experimental Forth-based circuit board design tool. It
integrates pForth with SDL2 to provide graphics display capabilities in a
portable and lightweight Forth environment.

## Design

SDL and Forth don't naturally fit together. SDL is a C library through and
through, and doesn't conform exactly to Forth calling conventions. To integrate
the two, BoardForth embeds the pForth interpreter within an SDL application. SDL
runs on the main thread, controlling a rendering stack used to display a system
window. A sub-thread executes pForth. The two threads share a common pixel
buffer, whose access is managed using an SDL mutex lock. These structures are
exposed by C functions linked into the Forth dictionary, allowing the two
programs to communicate.

The main thread is responsible for monitoring the SDL event loop and exiting if
the app is quit, as well as waiting for a semaphore to be set by the Forth code
and triggering a re-render of the pixel buffer to the display. If the Forth
interpreter exits it sets another semaphore indicating to the main loop that it
should exit.

Drawing primitives are provided as Forth words, implemented using pixel-level
operations. This allows easy iteration and does not require a separate
compilation step.
