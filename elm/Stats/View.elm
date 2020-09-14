module Stats.View exposing (view)

import Common.Types exposing (..)
import Common.View exposing (..)
import Config
import Dict exposing (Dict)
import Dict.Extra
import Element exposing (Element, height, padding, px, spacing, width)
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Element.Input
import Eth.Types exposing (Address)
import Eth.Utils
import Helpers.Element as EH exposing (DisplayProfile(..), changeForMobile, responsiveVal)
import Helpers.Tuple as TupleHelpers
import Routing exposing (Route)
import Stats.Types exposing (..)
import Theme exposing (darkTheme, defaultTheme)
import TokenValue exposing (TokenValue)
import Wallet exposing (Wallet)


view : EH.DisplayProfile -> Model -> Maybe UserInfo -> Element Msg
view dProfile model maybeUserInfo =
    Element.column []
        [ Element.row []
            [ Element.el
                [ Element.Font.color EH.white, Element.Font.size 30 ]
              <|
                Element.text " Foundry Addresses"
            ]
        , viewAddressAndLabel "FRY token" Config.fryTokenAddress
        , viewAddressAndLabel "Treasury" Config.treasuryForwarderAddress
        , viewAddressAndLabel "Bucket sale" Config.bucketSaleAddress
        , viewAddressAndLabel "Multisig" Config.teamToastMultiSigAddress
        ]


viewAddressAndLabel : String -> Address -> Element Msg
viewAddressAndLabel label address =
    Element.row [ padding 5, spacing 5, height (px 50) ]
        [ Element.el
            [ Element.Font.color EH.white ]
          <|
            Element.text <|
                label
                    ++ ": "
        , Element.el
            [ Element.Font.color EH.white ]
          <|
            Element.newTabLink []
                { url = Config.etherscanBaseUrl ++ Eth.Utils.addressToString address
                , label = Element.text (Eth.Utils.addressToString address)
                }
        ]
