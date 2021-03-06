module Macbeth.Fics.Api.Api where

import Data.Char
import Data.List
import Data.Monoid

data Column = A | B | C | D | E | F | G | H deriving (Show, Enum, Bounded, Eq)

data Row = One | Two | Three | Four | Five | Six | Seven | Eight deriving (Show, Eq, Enum, Bounded)

data Square = Square Column Row deriving (Eq)

instance Show Square where
  show (Square s y) = fmap toLower (show s) ++ show (fromEnum y + 1)

data PType = Pawn | Bishop | Knight | Rook | Queen | King deriving (Ord, Eq)

instance Show PType where
  show Pawn = "P"
  show Rook = "R"
  show Knight = "N"
  show Bishop = "B"
  show Queen = "Q"
  show King = "K"

data PColor = Black | White deriving (Show, Eq, Read, Ord)

squareColor :: Square -> PColor
squareColor (Square col row)
  | (even $ fromEnum col) && (even $ fromEnum row) = Black
  | (odd $ fromEnum col) && (odd $ fromEnum row) = Black
  | otherwise = White

data Piece = Piece PType PColor deriving (Show, Eq, Ord)

getPieceType :: Piece -> PType
getPieceType (Piece ptype _) = ptype

type Position = [(Square, Piece)]

data MoveDetailed = Simple Square Square | Drop Square | CastleLong | CastleShort deriving (Show, Eq)

newtype GameId = GameId Int deriving (Eq)

instance Show GameId where
  show (GameId i) = show i

instance Ord GameId where
  compare (GameId gi1) (GameId gi2) = gi1 `compare` gi2


pColor :: Piece -> PColor
pColor (Piece _ color) = color


hasColor :: PColor -> Piece -> Bool
hasColor color (Piece _ pc) = pc == color


removePiece :: Position -> Square -> Position
removePiece pos sq = filter (\(sq', _) -> sq /= sq') pos


getPiece :: Position -> Square -> Maybe Piece
getPiece p sq = sq `lookup` p


getSquare :: Position -> Piece -> Maybe Square
getSquare pos p = fst <$> find ((== p) . snd) pos


invert :: PColor -> PColor
invert White = Black
invert Black = White


newtype ChannelId = ChannelId Int deriving (Eq, Ord)


data ChatId = UserChat String | GameChat GameId | ChannelChat ChannelId deriving (Eq, Ord)


instance Show ChatId where
  show (UserChat username) = username
  show (GameChat gameId) = "Game " <> show gameId
  show (ChannelChat channelId) = "Channel " <> show channelId


instance Show ChannelId where
  show (ChannelId cid) = show cid

newtype CommandId = CommandId Int deriving (Show, Eq)

