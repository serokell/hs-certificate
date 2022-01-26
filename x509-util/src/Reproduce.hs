{-# LANGUAGE NumericUnderscores #-}

import Control.Monad

import Control.Concurrent

import System.X509.MacOS

main :: IO ()
main = do
  let run = forever getSystemCertificateStore

  threadIds <- replicateM 3 $ forkIO run

  threadDelay 3_000_000
  mapM_ killThread threadIds
  threadDelay 0_100_000
