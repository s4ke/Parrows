module Main where

import Parrows.Definition
import Parrows.Future
import Control.Parallel.Eden.Topology
--import Parrows.Skeletons.Topology
import Parrows.Eden
import Data.List

import Control.Applicative
import Data.Functor
import Data.List.Split

import Control.DeepSeq

type Vector = [Int]
type Matrix = [Vector]

dimX :: Matrix -> Int
dimX = length

dimY :: Matrix -> Int
dimY = length . head

--from: https://rosettacode.org/wiki/Matrix_multiplication#Haskell
foldlZipWith::(a -> b -> c) -> (d -> c -> d) -> d -> [a] -> [b]  -> d
foldlZipWith _ _ u [] _          = u
foldlZipWith _ _ u _ []          = u
foldlZipWith f g u (x:xs) (y:ys) = foldlZipWith f g (g u (f x y)) xs ys

foldl1ZipWith::(a -> b -> c) -> (c -> c -> c) -> [a] -> [b] -> c
foldl1ZipWith _ _ [] _          = error "First list is empty"
foldl1ZipWith _ _ _ []          = error "Second list is empty"
foldl1ZipWith f g (x:xs) (y:ys) = foldlZipWith f g (f x y) xs ys

multAdd::(a -> b -> c) -> (c -> c -> c) -> [[a]] -> [[b]] -> [[c]]
multAdd f g xs ys = map (\us -> foldl1ZipWith (\u vs -> map (f u) vs) (zipWith g) us ys) xs

matMult:: Num a => [[a]] -> [[a]] -> [[a]]
matMult xs ys = multAdd (*) (+) xs ys

matAdd :: Matrix -> Matrix -> Matrix
matAdd x y
    | dimX x /= dimX y = error "dimX x not equal to dimX y"
    | dimY x /= dimY y = error "dimY x not equal to dimY y"
    | otherwise = chunksOf (dimX x) $ zipWith (+) (concat x) (concat y)

-- from: http://www.mathematik.uni-marburg.de/~eden/paper/edenCEFP.pdf (page 38)
nodefunction :: Int                         -- torus dimension
    -> ((Matrix, Matrix), [Matrix], [Matrix]) -- process input
    -> ([Matrix], [Matrix], [Matrix])       -- process output
nodefunction n ((bA, bB), rows, cols)
    = ([bSum], bA:nextAs , bB:nextBs)
    where bSum = foldl' matAdd (matMult bA bB) (zipWith matMult nextAs nextBs)
          nextAs = take (n-1) rows
          nextBs = take (n-1) cols

testMatrix :: Matrix
testMatrix = replicate 10 [1..10]

--main = print $ torus () (nodefunction 8) [[(testMatrix, testMatrix)]]
main = print $ (rnf val) `seq` val
    where
        val = torus (\ x y z -> nodefunction 2 (x, y, z)) $ [[(testMatrix, testMatrix), (testMatrix, testMatrix)]]
