{-# OPTIONS_GHC -Wno-partial-type-signatures #-}

{-# LANGUAGE TemplateHaskell, DeriveGeneric, RecordWildCards #-}
{-# LANGUAGE PartialTypeSignatures, NamedWildCards #-}

module TestTools where

import           NgxExport
import           NgxExport.Tools

import           Data.ByteString (ByteString)
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString.Lazy.Char8 as C8L
import           Data.Aeson
import           Data.IORef
import           Control.Monad
import           GHC.Generics

test :: ByteString -> Bool -> IO L.ByteString
test = const . return . L.fromStrict
ngxExportSimpleService 'test $
    PersistentService $ Just $ Sec 10

showAsLazyByteString :: Show a => a -> L.ByteString
showAsLazyByteString = C8L.pack . show

testRead :: Show a => a -> IO L.ByteString
testRead = return . showAsLazyByteString

testReadInt :: Int -> Bool -> IO L.ByteString
testReadInt = const . testRead
ngxExportSimpleServiceTyped 'testReadInt ''Int $
    PersistentService $ Just $ Sec 10

newtype Conf = Conf Int deriving (Read, Show)

testReadConf :: Conf -> Bool -> IO L.ByteString
testReadConf = const . testRead
ngxExportSimpleServiceTyped 'testReadConf ''Conf $
    PersistentService $ Just $ Sec 10

testConfStorage :: ByteString -> IO L.ByteString
testConfStorage = const $
    showAsLazyByteString <$> readIORef storage_Conf_testReadConf
ngxExportIOYY 'testConfStorage

data ConfWithDelay = ConfWithDelay { delay :: TimeInterval
                                   , value :: Int
                                   } deriving (Read, Show)

testReadConfWithDelay :: ConfWithDelay -> Bool -> IO L.ByteString
testReadConfWithDelay c@ConfWithDelay {..} fstRun = do
    unless fstRun $ threadDelaySec $ toSec delay
    testRead c
ngxExportSimpleServiceTyped 'testReadConfWithDelay ''ConfWithDelay $
    PersistentService Nothing

data ConfJSON = ConfJSONCon1 Int
              | ConfJSONCon2 deriving (Generic, Show)
instance FromJSON ConfJSON

testReadConfJSON :: ConfJSON -> Bool -> IO L.ByteString
testReadConfJSON = ignitionService testRead
ngxExportSimpleServiceTypedAsJSON 'testReadConfJSON ''ConfJSON
    SingleShotService

testReadIntHandler :: ByteString -> L.ByteString
testReadIntHandler = showAsLazyByteString .
    (readFromByteString :: _s -> Maybe Int)
ngxExportYY 'testReadIntHandler

testReadConfHandler :: ByteString -> L.ByteString
testReadConfHandler = showAsLazyByteString .
    (readFromByteString :: _s -> Maybe Conf)
ngxExportYY 'testReadConfHandler

testReadConfJSONHandler :: ByteString -> IO L.ByteString
testReadConfJSONHandler = return . showAsLazyByteString .
    (readFromByteStringAsJSON :: _s -> Maybe ConfJSON)
ngxExportAsyncIOYY 'testReadConfJSONHandler

testReadConfWithRPtrHandler :: ByteString -> L.ByteString
testReadConfWithRPtrHandler = showAsLazyByteString .
    (readFromByteStringWithRPtr :: _s -> (_p, Maybe Conf))
ngxExportYY 'testReadConfWithRPtrHandler

testReadConfWithRPtrJSONHandler :: ByteString -> L.ByteString
testReadConfWithRPtrJSONHandler = showAsLazyByteString .
    (readFromByteStringWithRPtrAsJSON :: _s -> (_p, Maybe ConfJSON))
ngxExportYY 'testReadConfWithRPtrJSONHandler

