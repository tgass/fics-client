{-# LANGUAGE OverloadedStrings #-}

module PlayersSpec (spec) where

import qualified Macbeth.Fics.Api.Rating as R
import Macbeth.Fics.Message
import Macbeth.Fics.Api.Player
import Macbeth.Fics.Parsers.Players

import Test.Hspec
import Data.Attoparsec.ByteString.Char8


spec :: Spec
spec =
  describe "Players" $ do

    it "single player, Unregistered" $ parseOnly player' "++++^TeachMATE(U)\n"
      `shouldBe` Right (Player R.Guest InvolvedInAGame (UserHandle "TeachMATE" [Unregistered]))

    it "single player 2, with space" $ parseOnly player' "1173.kalithkar  "
      `shouldBe` Right (Player (R.Rating 1173 R.None) InactiveOrBusy (UserHandle "kalithkar" []))

    it "single player, Admin & TournamentDirectorOrBot" $ parseOnly player' "----:adminBOT(*)(TD)"
      `shouldBe` Right (Player R.Unrated NotOpenForMatch (UserHandle "adminBOT" [Admin,ServiceRepresentative]))

    it "players" $ parseOnly players' "\n2985.BigMomma(C)                 ++++ xcx(U)\n1123^littledul                \n\n 1055 players displayed (of 1055). (*) indicates system administrator.\n\ETB"
      `shouldBe` Right [Player (R.Rating 2985 R.None) InactiveOrBusy (UserHandle "BigMomma" [Computer]),Player R.Guest NotBusy (UserHandle "xcx" [Unregistered]),Player (R.Rating 1123 R.None) InvolvedInAGame (UserHandle "littledul" [])]

    it "check num players in block" $ fmap (\(Players x) -> length x) (parseOnly players "\NAK5\SYN146\SYN\n2985.BigMomma(C)                 ++++ xcx(U)\n1123^littledul                \n\n 1055 players displayed (of 1055). (*) indicates system administrator.\n\ETB")
      `shouldBe` Right 3

    it "check num players in block 2" $ fmap (\(Players x) -> length x) (parseOnly players "\NAK5\SYN146\SYN\n2985.BigMomma(C)                 ++++ xcx(U)\n\n 1055 players displayed (of 1055). (*) indicates system administrator.\n\ETB")
      `shouldBe` Right 2

    it "bughouse partner offer" $ parseOnly partnerOffer "GuestZTCG offers to be your bughouse partner; type \"partner GuestZTCG\" to accept.\n"
      `shouldBe` Right (PartnerOffer (UserHandle "GuestZTCG" []))

    it "bughouse partner accepted" $ parseOnly partnerAccepted "GuestCCGS agrees to be your partner.\n"
      `shouldBe` Right (PartnerAccepted (UserHandle "GuestCCGS" []))

    it "bughouse partner declined" $ parseOnly partnerDeclined "GuestCCGS declines the partnership request.\n"
      `shouldBe` Right (PartnerDeclined (UserHandle "GuestCCGS" []))

    it "bughouse partner not open" $ parseOnly partnerNotOpen "\NAK6\SYN84\SYNzerowin is not open for bughouse.\n\ETB\n"
      `shouldBe` Right (PartnerNotOpen (UserHandle "zerowin" []))

    it "finger" $ parseOnly finger "\NAK6\SYN37\SYNFinger of raffa:\n\nOn for: 6 mins   Idle: 13 secs\n(playing  Who knew?\n\ETB\n"
      `shouldBe` Right (Finger (UserHandle "raffa" []) "\n\nOn for: 6 mins   Idle: 13 secs\n(playing  Who knew?\n")

    it "history" $ parseOnly history "\NAK6\SYN51\SYN\nHistory for Guffster:\n                  Opponent      Type         ECO End Date\n76: - 1337 B 1490 vitaliyS      [ br  5   0] B06 Res Wed Feb 10, 18:29 EST 2016\n77: + 1348 W 1466 vitaliyS      [ br  5   0] C23 Mat Wed Feb 10, 18:38 EST 2016\n\ETB"
      `shouldBe` Right (History (UserHandle "Guffster" []) "\n                  Opponent      Type         ECO End Date\n76: - 1337 B 1490 vitaliyS      [ br  5   0] B06 Res Wed Feb 10, 18:29 EST 2016\n77: + 1348 W 1466 vitaliyS      [ br  5   0] C23 Mat Wed Feb 10, 18:38 EST 2016\n")
