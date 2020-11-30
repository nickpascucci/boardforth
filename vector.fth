\ Vector drawing utilities.
\
\ This file provides vector primitives which loosely mirror those defined by the
\ Gerber file format, with the aim of enabling easy conversion into that format.

\ "There are four types of graphics objects:
\
\ 1. Draws are straight-line segments, stroked with the current aperture, which
\ must be a solid circular one.
\ 2. Arcs are circular segments, stroked with the current aperture, which must
\ be a solid circular one.
\ 3. Flashes are replications of the current aperture in the image plane. Any
\ valid aperture can be flashed (see 4.7.5). An aperture is typically flashed
\ many times.
\ 4. Regions are defined by its contour (see 4.10.1). A contour is a closed
\ sequence of connected linear or circular segments.
\
\ In PCB copper layers, tracks are typically represented by draws and arcs, pads
\ by flashes and copper pours by regions. Tracks is then a generic name for
\ draws and arcs."
\
\ Gerber File Format Specification, Section 2.3

