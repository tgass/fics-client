module Lentils.Utils.FEN (
  available,
  convert
) where

import Lentils.Api.Api
import Lentils.Api.Move

import Data.Maybe
import Data.List.Utils


convert :: Move -> String
convert m = piecePlacement (positionRaw m) ++ " " ++
        activeColor (turn m) ++ " " ++
        castlingAv' (castlingAv m) ++ " " ++
        enPassant (turn m) (doublePawnPush m) ++ " " ++
        show (ply m) ++ " " ++
        show (moveNumber m)

available :: Move -> Bool
available = isJust . movePretty

enPassant :: PColor -> Maybe Column -> String
enPassant Black (Just c) = show $ Square c Three
enPassant White (Just c) = show $ Square c Six
enPassant _ _ = "-"


castlingAv' :: [Castling] -> String
castlingAv' [] = "-"
castlingAv' cx = concat $ fmap castlingToStr cx


castlingToStr WhiteLong = "Q"
castlingToStr WhiteShort = "K"
castlingToStr BlackLong = "q"
castlingToStr BlackShort = "k"


activeColor :: PColor -> String
activeColor White = "w"
activeColor Black = "b"


piecePlacement :: String -> String
piecePlacement = replace " " "/" . emptySquares 8


emptySquares :: Int -> String -> String
emptySquares num str
  | num == 0 = str
  | otherwise = emptySquares (num-1)  (replace (replicate num '-') (show num) str)
