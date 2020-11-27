# BoardForth

BoardForth is an experimental Forth-based circuit board design tool. It
integrates pForth with SDL2 to provide graphics display capabilities in a
portable and lightweight Forth environment.

## Design

SDL and Forth don't naturally fit together. SDL is a C library through and
through, and doesn't conform exactly to Forth calling conventions. To integrate
the two, BoardForth is implemented as a set of C functions which wrap SDL calls
and provide conversions between Forth and C types. Because pForth is
single-threaded, in order to support interactivity these functions also manage
a separate UI thread and control access to shared resources.

The Forth thread executes the pForth interpreter which provides the primary
interactive interface. The main thread holds a reference to an SDL rendering
stack. The main thread is responsible for:

- monitoring the SDL event loop and exiting if the app is quit;
- waiting on a semaphore to be set by the Forth code to trigger a re-draw of the
  graphical UI;
- listening for a Semaphore indicating Forth has exited and quitting the application.
