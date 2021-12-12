import Control.Monad

import Control.Concurrent

import System.X509.MacOS

main :: IO ()
main = do
  let run = forever getSystemCertificateStore

  replicateM_ 2 $ forkIO run
  run
