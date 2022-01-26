{-# LANGUAGE LambdaCase   #-}
{-# LANGUAGE BangPatterns #-}

module System.X509.MacOS
    ( getSystemCertificateStore
    ) where

import qualified Data.ByteString.Lazy as LBS
import Data.Either
import Data.PEM (PEM (..), pemParseLBS)
import System.Exit
import System.Process

import Data.X509
import Data.X509.CertificateStore

rootCAKeyChain :: FilePath
rootCAKeyChain = "/System/Library/Keychains/SystemRootCertificates.keychain"

systemKeyChain :: FilePath
systemKeyChain = "/Library/Keychains/System.keychain"

listInKeyChains :: [FilePath] -> IO [SignedCertificate]
listInKeyChains keyChains = do
    withCreateProcess (proc "security" ("find-certificate" : "-pa" : keyChains)) { std_out = CreatePipe } $
      \_ (Just hout) _ ph -> do
        !ePems <- pemParseLBS <$> LBS.hGetContents hout
        let eTargets = rights . map (decodeSignedCertificate . pemContent) . filter ((=="CERTIFICATE") . pemName)
                    <$> ePems
        waitForProcess ph >>= \case
            ExitFailure (-2) ->
                -- This case means that the application is shutting down,
                -- 'find-certificate' thread has been killed first but
                -- our thread is yet waiting for exception.
                pure ()
            ExitFailure code ->
                error $ "find-certificate process failed with code " <> show code
            _ ->
                pure ()
        either error pure eTargets

getSystemCertificateStore :: IO CertificateStore
getSystemCertificateStore = makeCertificateStore <$> listInKeyChains [rootCAKeyChain, systemKeyChain]
