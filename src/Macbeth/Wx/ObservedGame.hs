{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Macbeth.Wx.ObservedGame (
  createObservedGame
) where

import Macbeth.Fics.Api.Api
import Macbeth.Fics.FicsMessage hiding (gameId)
import Macbeth.Fics.Api.Move
import Macbeth.Utils.PGN
import qualified Macbeth.Wx.BoardState as Api
import Macbeth.Wx.Utils
import Macbeth.Wx.PieceSet
import Macbeth.Wx.StatusPanel
import qualified Macbeth.Wx.Board as Board

import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception
import Control.Monad
import Data.Maybe
import Graphics.UI.WX hiding (when, position)
import Graphics.UI.WXCore hiding (when, Timer)
import System.IO

eventId = wxID_HIGHEST + 1

createObservedGame :: Handle -> Move -> Chan FicsMessage -> IO ()
createObservedGame h move chan = do
  vCmd <- newEmptyMVar
  f <- frame [ text := "[Game " ++ show (gameId move) ++ "] " ++ nameW move ++ " vs " ++ nameB move]
  p_back <- panel f []

  -- board
  let boardState = Api.initBoardState move
  vBoardState <- newTVarIO boardState
  p_board <- panel p_back [ on paint := Board.draw vBoardState ]

  -- player panels
  (p_white, tiClockW) <- createStatusPanel p_back White vBoardState (eventId + 1) chan
  (p_black, tiClockB) <- createStatusPanel p_back Black vBoardState (eventId + 2) chan

  -- layout helper
  let updateBoardLayoutIO = updateBoardLayout p_back p_board p_white p_black vBoardState >> refit f
  updateBoardLayoutIO

  -- context menu
  ctxMenu <- menuPane []
  menuItem ctxMenu [ text := "Turn board", on command :=
    Api.invertPerspective vBoardState >> updateBoardLayoutIO >> repaint p_board]
  when (isGameUser move) $ do
     menuLine ctxMenu
     menuItem ctxMenu [ text := "Request takeback 1", on command := hPutStrLn h "4 takeback 1"]
     menuItem ctxMenu [ text := "Request takeback 2", on command := hPutStrLn h "4 takeback 2"]
     menuItem ctxMenu [ text := "Request abort", on command := hPutStrLn h "4 abort"]
     menuItem ctxMenu [ text := "Offer draw", on command := hPutStrLn h "4 draw" ]
     menuItem ctxMenu [ text := "Resign", on command := hPutStrLn h "4 resign" ]
     windowOnMouse p_board True (\x -> Board.onMouseEvent h vBoardState x >> repaint p_board)
     windowOnKeyChar p_back $ cancelLastPreMove vBoardState p_back
  menuLine ctxMenu
  wxPieceSetsMenu ctxMenu vBoardState p_board

  -- status line
  status <- statusField []

  -- key handler
  let acceptDeclineKeyHandler keyboard = case keyKey keyboard of
       KeyChar 'y' -> do
         hPutStrLn h "5 accept"
         set status [ text := ""]
         windowOnKeyChar p_back $ cancelLastPreMove vBoardState p_back
       KeyChar 'n' -> do
         hPutStrLn h "5 decline"
         set status [ text := ""]
         windowOnKeyChar p_back $ cancelLastPreMove vBoardState p_back
       _ -> return ()


  set p_board [ on clickRight := (\pt -> menuPopup ctxMenu pt p_board) ]
  set f [ statusBar := [status], layout := fill $ widget p_back, on resize := resizeFrame f vBoardState p_board]

  -- necessary: after GameResult no more events are handled
  tiClose <- dupChan chan >>= registerWxCloseEventListenerWithThreadId f

  threadId <- forkIO $ eventLoop eventId chan vCmd f
  evtHandlerOnMenuCommand f eventId $ takeMVar vCmd >>= \case

    GameMove ctx move' -> when (gameId move' == gameId move) $ do
      set status [text := show ctx]
      Api.update vBoardState move' ctx
      when (isNextMoveUser move') $ Api.handlePreMoves vBoardState h
      repaint p_board

    GameResult id reason result -> when (id == gameId move) $ do
      windowOnMouse p_board True (\_ -> return ())
      windowOnKeyChar p_board (\_ -> return ())
      set status [text := (show result ++ " " ++ reason)]
      Api.setResult vBoardState result
      repaint p_board
      hPutStrLn h "4 iset seekinfo 1"
      sequence_ $ fmap killThread [threadId, tiClockW, tiClockB]

    DrawRequest -> do
      set status [text := nameOponent move ++ " offered a draw. Accept? (y/n)"]
      windowOnKeyChar p_back acceptDeclineKeyHandler

    DrawRequestDeclined user -> set status [text := user ++ " declines the draw request."]

    AbortRequest user -> do
      set status [text := user ++ " would like to abort the game. Accept? (y/n)"]
      windowOnKeyChar p_back acceptDeclineKeyHandler

    AbortRequestDeclined user -> set status [text := user ++ " declines the abort request."]

    TakebackRequest user numTakeback -> do
      set status [text := user ++ " would like to take back " ++ show numTakeback ++ " half move(s). Accept? (y/n)"]
      windowOnKeyChar p_back acceptDeclineKeyHandler

    _ -> return ()

  windowOnDestroy f $ do
    sequence_ $ fmap (handle (\(_ :: IOException) -> return ()) . killThread) [threadId, tiClockW, tiClockB, tiClose]
    boardState <- readTVarIO vBoardState
    when (isGameUser move) $ saveAsPGN boardState
    unless (isJust $ Api.gameResult boardState) $ case relation move of
      MyMove -> hPutStrLn h "5 resign"
      OponentsMove -> hPutStrLn h "5 resign"
      Observing -> hPutStrLn h $ "5 unobserve " ++ show (gameId move)
      _ -> return ()


resizeFrame :: Frame () -> TVar Api.BoardState -> Panel() -> IO ()
resizeFrame f vBoardState p_board = do
  (Size w h) <- windowGetClientSize f
  Api.resize p_board vBoardState
  let x = max w (h-66)
  windowSetClientSize f $ Size x (x+66)
  void $ windowLayout f


cancelLastPreMove :: TVar Api.BoardState -> Panel () -> EventKey -> IO ()
cancelLastPreMove vBoardState panel keyboard = case keyKey keyboard of
  KeyChar 'x' -> Api.cancelLastPreMove vBoardState >> repaint panel
  _ -> return ()


updateBoardLayout :: Panel() -> Panel() -> Panel() -> Panel() -> TVar Api.BoardState -> IO ()
updateBoardLayout pback board white black vBoardState = do
  state <- readTVarIO vBoardState
  set pback [ layout := column 0 [ hfill $ widget (if Api.perspective state == White then black else white)
                                 , stretch $ minsize (Size 320 320) $ shaped $ widget board
                                 , hfill $ widget (if Api.perspective state == White then white else black)]]


wxPieceSetsMenu :: Menu () -> TVar Api.BoardState -> Panel () -> IO ()
wxPieceSetsMenu ctxMenu vState p = do
  sub <- menuPane [text := "Piece Sets"]
  mapM_ (\ps -> menuItem sub [ text := display ps, on command := Api.setPieceSet vState ps >> repaint p ]) pieceSets
  void $ menuSub ctxMenu sub [ text := "Piece Sets" ]

