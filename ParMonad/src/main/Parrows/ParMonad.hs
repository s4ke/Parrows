{-
The MIT License (MIT)

Copyright (c) 2016 Martin Braun

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
{-# LANGUAGE FlexibleInstances, UndecidableInstances, MultiParamTypeClasses #-}
module Parrows.ParMonad where

import Parrows.Definition
import Parrows.Future
import Parrows.Util

import Control.Monad.Par
import Control.Arrow
import Control.DeepSeq

instance (NFData b, ArrowApply arr, ArrowChoice arr) => ArrowParallel arr a b conf where
    parEvalN _ fs = (arr $ \as -> (fs, as)) >>>
                    zipWithArr (app >>> arr spawnP) >>>
                    arr sequenceA >>>
                    arr (>>= mapM Control.Monad.Par.get) >>>
                    arr runPar

data BasicFuture a = BF { val :: a }
instance (NFData a) => NFData (BasicFuture a) where
    rnf = rnf . val

instance (NFData a) => Future BasicFuture a where
    put = arr (\a -> BF { val = a })
    get = arr val
