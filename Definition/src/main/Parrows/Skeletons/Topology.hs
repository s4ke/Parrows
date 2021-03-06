{-
The MIT License (MIT)

Copyright (c) 2016-2017 Martin Braun

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module Parrows.Skeletons.Topology where

import           Control.Arrow

import           Parrows.Definition
import           Parrows.Future
import           Parrows.Util

-- Ports of Control.Parallel.Eden.Topology to Parrows:
-- edenskel-2.0.0.2 and the paper:
-- http://www.mathematik.uni-marburg.de/~eden/paper/edenCEFP.pdf

(|>>>|) :: (ArrowLoop arr, ArrowChoice arr,
            ArrowLoopParallel arr (fut (([a], [b]), [c])) (fut (([a], [b]), [c])) (),
            Future fut (([a], [b]), [c]) ()) =>
            arr a b -> arr b c -> arr a c
(|>>>|) = pipe2 ()

pipe2 :: (ArrowLoop arr, ArrowChoice arr,
            ArrowLoopParallel arr (fut (([a], [b]), [c])) (fut (([a], [b]), [c])) conf,
            Future fut (([a], [b]), [c]) conf) =>
            conf -> arr a b -> arr b c -> arr a c
pipe2 conf f g =
    (arr return &&& arr (const [])) &&& arr (const []) >>>
    pipe conf (replicate 2 (unify f g)) >>>
    arr snd >>>
    arr head
    where
        unify :: (ArrowChoice arr) => arr a b -> arr b c -> arr (([a], [b]), [c]) (([a], [b]), [c])
        unify f' g' = (mapArr f' *** mapArr g') *** arr (const []) >>> arr (\((b, c), a) -> ((a, b), c))

pipe :: (ArrowLoop arr, ArrowLoopParallel arr (fut a) (fut a) conf, Future fut a conf) => conf -> [arr a a] -> arr a a
pipe conf fs = unliftFut conf (pipeSimple conf (map (liftFut conf) fs))

pipeSimple :: (ArrowLoop arr, ArrowLoopParallel arr a a conf) => conf -> [arr a a] -> arr a a
pipeSimple conf fs =
    loop (arr snd &&&
        (arr (uncurry (:) >>> lazy) >>> loopParEvalN conf fs)) >>>
    arr last

ring :: (Future fut r conf,
    ArrowLoop arr,
    ArrowLoopParallel arr (i, fut r) (o, fut r) conf,
    ArrowLoopParallel arr o o conf) =>
    conf -> arr (i, r) (o, r) -> arr [i] [o]
ring conf f =
    loop (second (rightRotate >>> lazy) >>>
        arr (uncurry zip) >>>
        loopParEvalN conf (repeat (second (get conf) >>> f >>> second (put conf))) >>>
        arr unzip) >>>
    postLoopParEvalN conf (repeat (arr id))

--TODO: check whether this exchanges the futures the same way as Eden does it
torus :: (Future fut a conf, Future fut b conf,
      ArrowLoop arr, ArrowChoice arr,
      ArrowLoopParallel arr (c, fut a, fut b) (d, fut a, fut b) conf,
      ArrowLoopParallel arr [d] [d] conf) =>
      conf -> arr (c, a, b) (d, a, b) -> arr [[c]] [[d]]
torus conf f =
    loop (second ((mapArr rightRotate >>> lazy) *** (arr rightRotate >>> lazy)) >>>
        arr (uncurry3 (zipWith3 lazyzip3)) >>>
        arr length &&& (shuffle >>> loopParEvalN conf (repeat (ptorus conf f))) >>>
        arr (uncurry unshuffle) >>>
        arr (map unzip3) >>> arr unzip3 >>> threetotwo) >>>
    postLoopParEvalN conf (repeat (arr id))

uncurry3 :: (a -> b -> c -> d) -> (a, (b, c)) -> d
uncurry3 f (a, (b, c)) = f a b c

lazyzip3 :: [a] -> [b] -> [c] -> [(a, b, c)]
lazyzip3 as bs cs = zip3 as (lazy bs) (lazy cs)

ptorus :: (Arrow arr, Future fut a conf, Future fut b conf) =>
          conf ->
          arr (c, a, b) (d, a, b) ->
          arr (c, fut a, fut b) (d, fut a, fut b)
ptorus conf f = arr (\ ~(c, a, b) -> (c, get conf a, get conf b)) >>> f >>> arr (\ ~(d, a, b) -> (d, put conf a, put conf b))

threetotwo :: (Arrow arr) => arr (a, b, c) (a, (b, c))
threetotwo = arr $ \ ~(a, b, c) -> (a, (b, c))

twotothree :: (Arrow arr) => arr (a, (b, c)) (a, b, c)
twotothree = arr $ \ ~(a, (b, c)) -> (a, b, c)
