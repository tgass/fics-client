module Lentils.Api.Move (
  Move(..),
  Relation(..),
  Castling(..),
  remainingTime,
  decreaseRemainingTime,
  nameUser,
  colorUser,
  namePlayer,
  isGameUser,
  isNewGameUser,
  playerColor,
  nameOponent,
  isCheckmate,
  toGameResultTuple,
  dummyMove
) where

import Lentils.Api.Api
import qualified Lentils.Api.Game as Game

import Data.Maybe (isNothing)

data Move = Move {
    positionRaw :: String
  , position :: [(Square, Piece)]
  , turn :: PColor
  , doublePawnPush :: Maybe Column
  , castlingAv :: [Castling]
  , ply :: Int
  , gameId :: Int
  , nameW :: String
  , nameB :: String
  , relation :: Relation
  , moveNumber :: Int
  , moveVerbose :: String
  , timeTaken :: String
  , remainingTimeW :: Int
  , remainingTimeB :: Int
  , movePretty :: Maybe String
  } deriving (Eq, Show)

data Relation = MyMove | OponentsMove | Observing | Other deriving (Show, Eq)

data Castling = WhiteLong | WhiteShort | BlackLong | BlackShort deriving (Show, Eq)

remainingTime :: Lentils.Api.Api.PColor -> Move -> Int
remainingTime Black = remainingTimeB
remainingTime White = remainingTimeW


decreaseRemainingTime :: Lentils.Api.Api.PColor -> Move -> Move
decreaseRemainingTime Black move = move {remainingTimeB = max 0 $ remainingTimeB move - 1}
decreaseRemainingTime White move = move {remainingTimeW = max 0 $ remainingTimeW move - 1}


nameUser :: Move -> String
nameUser m = namePlayer (colorUser m) m


colorUser :: Move -> Lentils.Api.Api.PColor
colorUser m = if relation m == MyMove then turn m else Lentils.Api.Api.invert $ turn m

isGameUser :: Move -> Bool
isGameUser m = relation m `elem` [MyMove, OponentsMove]


isNewGameUser :: Move -> Bool
isNewGameUser m = isGameUser m && isNothing (movePretty m)


namePlayer :: Lentils.Api.Api.PColor -> Move -> String
namePlayer White = nameW
namePlayer Black = nameB


nameOponent :: Lentils.Api.Api.PColor -> Move -> String
nameOponent White = nameB
nameOponent Black = nameW


playerColor :: String -> Move -> Lentils.Api.Api.PColor
playerColor name move
  | nameW move == name = Lentils.Api.Api.White
  | otherwise = Lentils.Api.Api.Black


isCheckmate :: Move -> Bool
isCheckmate = maybe False ((== '#') . last) . movePretty

toGameResultTuple :: Move -> (Int, String, Game.GameResult)
toGameResultTuple move = (gameId move, namePlayer colorTurn move ++ " checkmated", turnToGameResult colorTurn)
  where
    colorTurn = turn move
    turnToGameResult Black = Game.WhiteWins
    turnToGameResult White = Game.BlackWins

dummyMove :: Move
dummyMove = Move {
    positionRaw = "",
    position = [ (Square A One, Piece Rook White)
                   , (Square A Two, Piece Pawn White)
                   , (Square B Two, Piece Pawn White)
                   , (Square C Two, Piece Pawn White)
                   , (Square E Eight, Piece King Black)
                   , (Square D Eight, Piece Queen Black)
                   ],
    turn = Black,
    doublePawnPush = Nothing,
    castlingAv = [],
    ply = 0,
    gameId = 1,
    nameW = "foobar",
    nameB = "barbaz",
    relation = MyMove,
    moveNumber = 0,
    moveVerbose = "none",
    timeTaken = "0",
    remainingTimeW = 0,
    remainingTimeB = 0,
    movePretty = Just "f2"
  }
