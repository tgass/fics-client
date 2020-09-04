module Macbeth.Fics.Parsers.PositionParser (
  parsePosition
) where

import Macbeth.Fics.Api.Api
import Control.Arrow (second)
import Data.List.Split
import Data.Maybe


parsePosition :: String -> [(Square, Piece)]
parsePosition str = second fromJust <$> filter (\(_,p) -> isJust p) squares
                where rows = parseRows str
                      squares = concatMap parseSquares rows

parseRows :: String -> [(Row, String)]
parseRows str = zip rows lines'
             where rows = [Eight, Seven .. One]
                   lines' = splitOn " " str


parseColumn :: String -> [(Column, Maybe Piece)]
parseColumn line = zip [A .. H] [readPiece c | c <- line]


parseSquares :: (Row, String) -> [(Square, Maybe Piece)]
parseSquares (r, line) = fmap (\cc -> (Square (fst cc) r, snd cc)) (parseColumn line)


readPiece :: Char -> Maybe Piece
readPiece 'P' = Just(Piece Pawn White)
readPiece 'R' = Just(Piece Rook White)
readPiece 'N' = Just(Piece Knight White)
readPiece 'B' = Just(Piece Bishop White)
readPiece 'Q' = Just(Piece Queen White)
readPiece 'K' = Just(Piece King White)
readPiece 'p' = Just(Piece Pawn Black)
readPiece 'r' = Just(Piece Rook Black)
readPiece 'n' = Just(Piece Knight Black)
readPiece 'b' = Just(Piece Bishop Black)
readPiece 'q' = Just(Piece Queen Black)
readPiece 'k' = Just(Piece King Black)
readPiece _ = Nothing
