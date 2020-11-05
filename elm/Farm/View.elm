module Farm.View exposing (..)

import Common.Types exposing (..)
import Common.View
import Config
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Eth.Types exposing (Address)
import Farm.Types exposing (..)
import Helpers.Element as EH exposing (DisplayProfile, responsiveVal)
import Images
import Maybe.Extra
import Theme
import Time
import TokenValue exposing (TokenValue)


view : DisplayProfile -> Maybe UserInfo -> Model -> Element Msg
view dProfile maybeUserInfo model =
    Element.el
        [ Element.width Element.fill
        , Element.paddingEach
            { top = responsiveVal dProfile 60 30
            , bottom = 0
            , left = 0
            , right = 0
            }
        ]
    <|
        Element.column
            [ Element.centerX
            , Element.Background.color <| Element.rgb 0.6 0.6 1
            , Element.Border.rounded 10
            , Element.height <| Element.px <| responsiveVal dProfile 500 500
            , Element.width <| Element.px <| responsiveVal dProfile 700 200

            -- , Element.Font.color EH.white
            -- , Element.Border.glow (Element.rgba 1 1 1 0.2) 6
            -- , Element.Border.width 3
            -- , Element.Border.color EH.black
            ]
            [ Element.el
                [ Element.Events.onClick FakeFetchBalanceInfo
                ]
                (Element.text "clicky")
            , case maybeUserInfo of
                Nothing ->
                    Common.View.web3ConnectButton
                        dProfile
                        [ Element.centerX
                        , Element.centerY
                        ]
                        MsgUp

                Just userInfo ->
                    case model.timedUserStakingInfo of
                        Nothing ->
                            Element.el
                                [ Element.centerX
                                , Element.centerY
                                , Element.Font.italic
                                ]
                                (Element.text "Fetching info...")

                        Just timedUserStakingInfo ->
                            Element.column
                                [ Element.spacing 15
                                ]
                                [ unstakedBalanceRow dProfile timedUserStakingInfo model.depositWithdrawUXModel userInfo
                                , maybeGetLiquidityMessageElement dProfile timedUserStakingInfo.userStakingInfo
                                , stakedBalanceRow dProfile timedUserStakingInfo.userStakingInfo.staked model.depositWithdrawUXModel
                                , rewardsAvailableRowAndUX dProfile userInfo.address timedUserStakingInfo model.now
                                ]
            ]


unstakedBalanceRow : DisplayProfile -> TimedUserStakingInfo -> DepositOrWithdrawUXModel -> UserInfo -> Element Msg
unstakedBalanceRow dProfile timedUserStakingInfo depositOrWithdrawUXModel userInfo =
    let
        maybeDepositAmountUXModel =
            case depositOrWithdrawUXModel of
                Just ( Deposit, amountUXModel ) ->
                    Just amountUXModel

                _ ->
                    Nothing
    in
    mainRow
        [ balanceLabel dProfile "Unstaked Balance"
        , balanceOutput dProfile timedUserStakingInfo.userStakingInfo.unstaked "ETHFRY"
        , depositExitUX dProfile userInfo.address timedUserStakingInfo.userStakingInfo maybeDepositAmountUXModel
        ]


maybeGetLiquidityMessageElement : DisplayProfile -> UserStakingInfo -> Element Msg
maybeGetLiquidityMessageElement dProfile stakingInfo =
    if TokenValue.isZero stakingInfo.staked && TokenValue.isZero stakingInfo.unstaked && TokenValue.isZero stakingInfo.claimableRewards then
        Element.row
            [ Element.centerX
            ]
            [ Element.newTabLink
                [ Element.Font.color Theme.blue ]
                { url = Config.urlToLiquidityPool
                , label = Element.text "Obtain ETHFRY Liquidity"
                }
            , Element.text " to continue."
            ]

    else
        Element.none


depositExitUX : DisplayProfile -> Address -> UserStakingInfo -> Maybe AmountUXModel -> Element Msg
depositExitUX dProfile userAddress balanceInfo uxModel =
    case uxModel of
        Nothing ->
            let
                maybeDepositStartButton =
                    if TokenValue.isZero balanceInfo.unstaked then
                        Nothing

                    else
                        Just <|
                            makeDepositButton StartDeposit

                maybeWithdrawStartButton =
                    if TokenValue.isZero balanceInfo.staked then
                        Nothing

                    else
                        Just <|
                            exitButton
            in
            Element.row
                [ Element.spacing 10
                ]
            <|
                Maybe.Extra.values
                    [ maybeDepositStartButton
                    , maybeWithdrawStartButton
                    ]

        Just amountInput ->
            Element.row
                [ Element.centerX
                , Element.spacing 5
                ]
                []


withdrawUX : DisplayProfile -> Maybe AmountUXModel -> Element Msg
withdrawUX dProfile maybeAmountUX =
    case maybeAmountUX of
        Nothing ->
            makeWithdrawButton StartWithdraw

        Just amountInput ->
            Debug.todo ""


makeDepositButton : Msg -> Element Msg
makeDepositButton onClick =
    Element.el
        (actionButtonStyles onClick)
    <|
        Images.toElement
            [ Element.centerX
            , Element.centerY
            , Element.width <| Element.px <| 40
            ]
            Images.stakingDeposit


makeWithdrawButton : Msg -> Element Msg
makeWithdrawButton onClick =
    Element.el
        (actionButtonStyles DoExit)
    <|
        Element.text "W"



-- Images.toElement
--     [ Element.centerX
--     , Element.centerY
--     , Element.width <| Element.px <| 40
--     ]
--     Images.stakingWithdraw


exitButton : Element Msg
exitButton =
    Element.el
        (actionButtonStyles DoExit)
    <|
        Images.toElement
            [ Element.centerX
            , Element.centerY
            , Element.width <| Element.px <| 40
            ]
            Images.stakingExit


actionButtonStyles : Msg -> List (Element.Attribute Msg)
actionButtonStyles onClick =
    [ Element.width <| Element.px 45
    , Element.height <| Element.px 45
    , Element.pointer
    , Element.Events.onClick onClick
    , Element.Background.color <| Element.rgba 1 1 1 0.2
    , Element.Border.rounded 6
    , Element.Border.width 1
    , Element.Border.color <| Element.rgba 0 0 0 0.2
    ]


stakedBalanceRow : DisplayProfile -> TokenValue -> DepositOrWithdrawUXModel -> Element Msg
stakedBalanceRow dProfile stakedBalance depositOrWithdrawUXModel =
    mainRow
        [ balanceLabel dProfile "Currently Staking"
        , balanceOutput dProfile stakedBalance "ETHFRY"
        , if TokenValue.isZero stakedBalance then
            Element.none

          else
            let
                maybeWithdrawAmountUXModel =
                    case depositOrWithdrawUXModel of
                        Just ( Withdraw, amountUXModel ) ->
                            Just amountUXModel

                        _ ->
                            Nothing
            in
            withdrawUX dProfile maybeWithdrawAmountUXModel
        ]


rewardsAvailableRowAndUX : DisplayProfile -> Address -> TimedUserStakingInfo -> Time.Posix -> Element Msg
rewardsAvailableRowAndUX dProfile userAddress balanceInfo now =
    mainRow
        [ balanceLabel dProfile "Available Rewards"
        , balanceOutput
            dProfile
            (calcAvailableRewards
                balanceInfo
                now
            )
            "FRY"
        ]


mainRow : List (Element Msg) -> Element Msg
mainRow =
    Element.row
        [ Element.width Element.fill
        , Element.spacing 30
        , Element.height <| Element.px 40
        ]


balanceLabel : DisplayProfile -> String -> Element Msg
balanceLabel dProfile text =
    Element.el
        [ Element.Font.size <| responsiveVal dProfile 30 24
        , Element.Font.alignRight
        , Element.width <| Element.px <| responsiveVal dProfile 280 240
        ]
        (Element.text text)


balanceOutput : DisplayProfile -> TokenValue -> String -> Element Msg
balanceOutput dProfile amount label =
    Element.row
        [ Element.Font.size <| responsiveVal dProfile 30 24
        , Element.spacing 4
        , Element.width <| Element.px 200
        ]
        [ Element.text <| TokenValue.toConciseString amount
        , Element.text label
        ]
