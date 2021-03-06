module Macbeth.Wx.Icons (
    Icon(..)
  , filepath
) where


import qualified Macbeth.Wx.Paths as Paths


data Icon = DesktopIcon | UserIcon | BullhornIcon | LightningIcon | UserSaysIcon | ListIcon | WrenchIcon


filepath :: Icon -> FilePath
filepath = Paths.iconFilepath . toFilename 


toFilename :: Icon -> String
toFilename DesktopIcon = "fa-desktop.gif"
toFilename UserIcon = "fa-user.gif"
toFilename BullhornIcon = "bullhorn.gif"
toFilename LightningIcon = "match.gif"
toFilename UserSaysIcon = "fa-question.gif"
toFilename ListIcon = "history.gif"
toFilename WrenchIcon = "settings.gif"

