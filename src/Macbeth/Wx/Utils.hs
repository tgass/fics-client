module Macbeth.Wx.Utils (
  eventLoop,
  listItemRightClickEvent,
  toWxColor,
  staticTextFormatted
) where

import Macbeth.Api.Api
import Macbeth.Api.CommandMsg

import Control.Concurrent.Chan
import Control.Concurrent.MVar
import Graphics.UI.WX
import Graphics.UI.WXCore


eventLoop :: Int -> Chan CommandMsg -> MVar CommandMsg -> Frame () -> IO ()
eventLoop id chan vCmd f = readChan chan >>= putMVar vCmd >>
  commandEventCreate wxEVT_COMMAND_MENU_SELECTED id >>= evtHandlerAddPendingEvent f >>
  eventLoop id chan vCmd f


listItemRightClickEvent :: ListCtrl a -> (Graphics.UI.WXCore.ListEvent () -> IO ()) -> IO ()
listItemRightClickEvent listCtrl eventHandler
  = windowOnEvent listCtrl [wxEVT_COMMAND_LIST_ITEM_RIGHT_CLICK] eventHandler listHandler
    where
      listHandler :: Graphics.UI.WXCore.Event () -> IO ()
      listHandler evt = eventHandler $ objectCast evt


toWxColor :: Macbeth.Api.Api.PColor -> Graphics.UI.WXCore.Color
toWxColor White = white
toWxColor Black = black

staticTextFormatted :: Panel () -> String -> IO (StaticText ())
staticTextFormatted p s = staticText p [ text := s
                                       , fontFace := "Avenir Next Medium"
                                       , fontSize := 20
                                       , fontWeight := WeightBold]
