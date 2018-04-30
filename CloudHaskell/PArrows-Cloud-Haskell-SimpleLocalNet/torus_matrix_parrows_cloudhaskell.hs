{-# LANGUAGE FlexibleInstances, FlexibleContexts, UndecidableInstances,
MultiParamTypeClasses, TemplateHaskell #-}
module Main where

--import Parrows.Eden
import Parrows.CloudHaskell.SimpleLocalNet hiding (put, get)
import Parrows.Definition
import Parrows.Future
import Parrows.Util
import Parrows.Skeletons.Topology
import Parrows.Skeletons.Map
import Data.List

--import Control.Parallel.Eden

--import GHC.Conc

import Control.Arrow
import Control.DeepSeq

import Control.DeepSeq

import Control.Applicative
import Data.Functor
import Data.List.Split

import Control.Concurrent

import System.Environment

import Debug.Trace
noPe = 4

randoms1 :: [Int]
randoms1 = cycle [4,5,6]

randoms2 :: [Int]
randoms2 = cycle [7,8,9]

type Vector = [Int]
type Matrix = [Vector]

dimX :: Matrix -> Int
dimX = length

dimY :: Matrix -> Int
dimY = length . head

matAdd :: Matrix -> Matrix -> Matrix
matAdd x y
    | dimX x /= dimX y = error "dimX x not equal to dimX y"
    | dimY x /= dimY y = error "dimY x not equal to dimY y"
    | otherwise = chunksOf (dimX x) $ zipWith (+) (concat x) (concat y)

toMatrix :: Int -> [Int] -> Matrix
toMatrix cnt randoms = chunksOf n $ take (matrixIntSize n) randoms
        where n = cnt

identity :: Int -> Matrix
identity size = [((replicate (shift) 0) ++ [1] ++ (replicate (size-1-shift) 0)) | shift <- [0..size-1]]

matrixIntSize :: Int -> Int
matrixIntSize n = n * n

splitMatrix :: Int -> Matrix -> [[Matrix]]
splitMatrix size matrix = (map (transpose . map (chunksOf size)) $ chunksOf size $ matrix)

prMM :: Matrix -> Matrix -> Matrix
prMM m1 m2 = prMMTr m1 (transpose m2)
prMMTr m1 m2 = [[sum (zipWith (*) row col) | col <- m2 ] | row <- m1]

--  1  2  3  4
--  5  6  7  8
--  9 10 11 12
-- 13 14 15 16

--let x = [[[[1,2],[5,6]],[[3,4],[7,8]]],[[[9,10],[13,14]],[[11,12],[15,16]]]]

numCoreCalc :: Int -> Int
numCoreCalc num
        | num <= 4 = 4
        | num <= 16 = 16
        | num <= 64 = 64
        | num <= 256 = 256
        | num <= 512 = 512
        | otherwise = error "too many cores!"

prMM_torus :: Conf -> Int -> Int -> Matrix -> Matrix -> Matrix
prMM_torus conf numCores problemSizeVal m1 m2 = combine $ torus conf (mult torusSize) $ zipWith zip (split1 m1) (split2 m2)
    where   torusSize = (floor . sqrt) $ fromIntegral $ numCoreCalc numCores
            combine x = concat (map ((map (concat)) . transpose) x)
            split1 x = staggerHorizontally (splitMatrix (problemSizeVal `div` torusSize) x)
            split2 x = staggerVertically (splitMatrix (problemSizeVal `div` torusSize) x)


--https://books.google.de/books?id=Hfnj5WmFVNUC&pg=PA499&lpg=PA499&dq=matrix+blockwise+multiplication+torus&source=bl&ots=H_jKeqVBJk&sig=GFIllvD9DKTXJaBMetoJyaLE-4A&hl=de&sa=X&ved=0ahUKEwjorcaTu9LYAhXEtBQKHQCVDSQQ6AEILjAB#v=onepage&q=matrix%20blockwise%20multiplication%20torus&f=false

staggerHorizontally :: [[a]] -> [[a]]
staggerHorizontally matrix = zipWith leftRotate [0..] matrix

staggerVertically :: [[a]] -> [[a]]
staggerVertically matrix = transpose $ zipWith leftRotate [0..] (transpose matrix)

leftRotate :: Int -> [a] -> [a]
leftRotate i xs = xs2 ++ xs1 where
    (xs1,xs2) = splitAt i xs

mult :: Int -> ((Matrix,Matrix),[Matrix],[Matrix]) -> (Matrix,[Matrix],[Matrix])
mult size ((sm1,sm2),sm1s,sm2s) = (result,toRight,toBottom)
    where toRight = take (size-1) (sm1:sm1s)
          toBottom = take (size-1) (sm2:sm2s)
          sms = zipWith prMM (sm1:sm1s) (sm2:sm2s)
          result = foldl1' matAdd sms

type MatrixList = [Matrix]

type MyType = (Matrix, CloudFuture [Matrix], CloudFuture [Matrix])

fun1 :: Conf -> Int -> CloudFuture Int
fun1 conf val = put conf (val + 1)

fun2 :: Conf -> CloudFuture Int -> Int
fun2 conf fut = (get conf fut) * 2

-- remotable declaration for all eval tasks
$(mkEvalTasks [''Matrix, ''MatrixList, ''MyType, ''Int])
$(mkRemotables [''Matrix, ''MatrixList, ''MyType, ''Int])
$(mkEvaluatables [''Matrix, ''MatrixList, ''MyType, ''Int])

myRemoteTable :: RemoteTable
myRemoteTable = Main.__remoteTable initRemoteTable

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["master", host, port] -> do
      (backend, state) <- startBackend myRemoteTable Master host port

      localNode <- newLocalNode backend

      conf <- defaultConf

      --readMVar (workers conf) >>= print
      -- wait a bit
      --threadDelay 1000000
      let problemSizeVal = 256
      let numCores = 4

      let matrixA = toMatrix problemSizeVal randoms1
      --let matrixB = identity problemSizeVal
      let matrixB = toMatrix problemSizeVal randoms2

      let matrixC = prMM_torus conf numCores problemSizeVal matrixA matrixB
      print $ length $ (rnf matrixC) `seq` matrixC

      

      -- TODO: actual computation here!
    ["slave", host, port] -> do
      startBackend myRemoteTable Slave host port
      print "slave shutdown."
