module Macbeth.Utils.Utils where

import           Control.Monad.State
import           Crypto.Cipher
import           Data.Char
import           Data.Aeson.Types
import           Data.List
import qualified Data.ByteString.Char8 as B
import           Macbeth.Utils.Salt


formatTime :: Int -> String
formatTime seconds = show h ++ " : " ++ format m ++ " : " ++ format s
  where
    (_, (h,m,s)) = runState (calc seconds) (0,0,0)

calc :: Int -> State (Int, Int, Int) Int
calc seconds
  | seconds >= 3600 = get >>= \(h, m, s) -> put (h+1, m, s) >> calc (seconds - 3600)
  | seconds >= 60 = get >>= \(h, m, s) -> put (h, m+1, s) >> calc (seconds - 60)
  | otherwise = get >>= \(h, m, _) -> put (h, m, max 0 seconds) >> return 0

format :: Int -> String
format i
  | i < 10 = "0" ++ show i
  | otherwise = show i

encrypt :: String -> String
encrypt = B.unpack . ctrCombine aes128 nullIV . B.pack
  where
    aes128 :: AES128
    aes128 = either (error . show) cipherInit $ makeKey (B.pack salt)

decrypt :: String -> String
decrypt = encrypt

customOptions :: String -> Options
customOptions prefix = defaultOptions { fieldLabelModifier = \label -> if prefix `isPrefixOf` label then lowerFirst (drop (length prefix) label) else label }

lowerFirst :: String -> String
lowerFirst [] = []
lowerFirst (x:xs) = toLower x : xs


