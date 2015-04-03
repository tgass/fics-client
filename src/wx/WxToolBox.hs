{-# LANGUAGE OverloadedStrings #-}

module WxToolBox (
  createToolBox
) where

import Api
import Move
import CommandMsg
import FicsConnection2 (ficsConnection)
import Game
import Seek
import Utils

import WxObservedGame
import WxChallenge

import Control.Applicative (liftA)
import Control.Concurrent
import Control.Concurrent.Chan
import Control.Monad (liftM)

import qualified Data.ByteString.Char8 as BS

import Graphics.UI.WX
import Graphics.UI.WXCore

import System.IO (Handle, hPutStrLn)

type Position = [(Square, Piece)]


ficsEventId :: Int
ficsEventId = wxID_HIGHEST + 51



createToolBox :: Handle -> String -> Chan CommandMsg -> IO ()
createToolBox h name chan = do
    vCmd <- newEmptyMVar

    -- main frame
    f  <- frame []
    mv <- newEmptyMVar

    -- right panel
    right <- panel f []
    nb <- notebook right []

    -- tab1 : Sought list
    slp <- panel nb []
    sl  <- listCtrl slp [columns := [ ("#", AlignLeft, -1)
                                    , ("handle", AlignLeft, -1)
                                    , ("rating", AlignLeft, -1)
                                    , ("game type", AlignRight, -1)]
                                    ]


    -- tab2 : console
    cp <- panel nb []
    ct <- textCtrlEx cp (wxTE_MULTILINE .+. wxTE_RICH) [font := fontFixed]
    ce <- entry cp []
    set ce [on enterKey := emitCommand ce h]


    -- tab3 : Games list
    glp <- panel nb []
    gl  <- listCtrl glp [columns := [("#", AlignLeft, -1)
                                    , ("player 1", AlignLeft, -1)
                                    , ("rating", AlignLeft, -1)
                                    , ("player 2", AlignLeft, -1)
                                    , ("rating", AlignLeft, -1)
                                    ]
                        ]

    set f [layout := minsize (Size 400 600) $ (container right $
                         column 0
                         [ tabs nb
                            [ tab "Sought" $ container slp $ fill $ widget sl
                            , tab "Games" $ container glp $ fill $ widget gl
                            , tab "Console" $ container cp $
                                            ( column 5  [ floatLeft $ expand $ hstretch $ widget ct
                                                        , expand $ hstretch $ widget ce])
                            ]
                         ]
                     )
          ]

    threadId <- forkIO $ loop chan vCmd f

    windowOnDestroy f $ killThread threadId

    evtHandlerOnMenuCommand f ficsEventId $ takeMVar vCmd >>= \cmd -> do
      putStrLn $ show cmd
      case cmd of
        Sought seeks -> do
          set sl [items := [[show id, name, show rat, show gt] | (Seek id rat name _ _ _ gt _ _) <- seeks]]
          set sl [on listEvent := onSeekListEvent seeks h]

        Games games -> do
          set gl [items := [[show id, n1, show r1, n2, show r2] | (Game id _ r1 n1 r2 n2 _) <- games]]
          set gl [on listEvent := onGamesListEvent games h]

        Observe move -> dupChan chan >>= createObservedGame h move White

        Match id -> putStrLn $ "new Match id=" ++ show id

        CommandMsg.Move move' -> if isPlayersNewGame move' then
                                   dupChan chan >>= createObservedGame h move' (playerColor name move')
                                 else return ()

        Accept move -> dupChan chan >>= createObservedGame h move (playerColor name move)

        c@(Challenge _ _ _ _ _) -> wxChallenge h c

        SettingsDone -> hPutStrLn h "5 sought" >> hPutStrLn h "4 games"

        TextMessage text -> appendText ct (BS.unpack text ++ "\n")

        cmd -> appendText ct (show cmd ++ "\n")



loop :: Chan CommandMsg -> MVar CommandMsg -> Frame () -> IO ()
loop chan vCmd f = readChan chan >>= putMVar vCmd >>
  commandEventCreate wxEVT_COMMAND_MENU_SELECTED ficsEventId >>= evtHandlerAddPendingEvent f >>
  loop chan vCmd f



onGamesListEvent :: [Game] -> Handle -> EventList -> IO ()
onGamesListEvent games h eventList = case eventList of
  ListItemActivated idx -> hPutStrLn h $ "4 observe " ++ show (Game.id $ games !! idx)
  _ -> return ()



onSeekListEvent :: [Seek] -> Handle -> EventList -> IO ()
onSeekListEvent seeks h eventList = case eventList of
  ListItemActivated idx -> hPutStrLn h $ "4 play " ++ show (Seek.id $ seeks !! idx)
  _ -> return ()



emitCommand :: TextCtrl () -> Handle -> IO ()
emitCommand textCtrl h = get textCtrl text >>= hPutStrLn h >> set textCtrl [text := ""]

