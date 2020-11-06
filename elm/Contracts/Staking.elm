module Contracts.Staking exposing (..)

import ChainCmd
import Common.Types exposing (UserStakingInfo)
import Config
import Contracts.Generated.ERC20 as ERC20
import Contracts.Generated.StakingRewards as StakingContract
import Contracts.Generated.StakingScripts as StakingScripts
import Eth
import Eth.Types as Eth exposing (Address)
import Helpers.Eth as EthHelpers
import Helpers.Time as TimeHelpers
import Http
import Task
import TokenValue exposing (TokenValue)


approveLiquidityToken : Eth.Send
approveLiquidityToken =
    ERC20.approve
        Config.stakingLiquidityContractAddress
        Config.stakingContractAddress
        (TokenValue.maxTokenValue |> TokenValue.getEvmValue)
        |> Eth.toSend


stake : TokenValue -> Eth.Send
stake amount =
    StakingContract.stake
        Config.stakingContractAddress
        (TokenValue.getEvmValue amount)
        |> Eth.toSend


withdraw : TokenValue -> Eth.Send
withdraw amount =
    StakingContract.withdraw
        Config.stakingContractAddress
        (TokenValue.getEvmValue amount)
        |> Eth.toSend


exit : Eth.Send
exit =
    StakingContract.exit
        Config.stakingContractAddress
        |> Eth.toSend


claimRewards : Eth.Send
claimRewards =
    StakingContract.getReward
        Config.stakingContractAddress
        |> Eth.toSend



-- callWithdraw : TokenValue -> (Result Http.Error () -> msg) -> Cmd msg
-- callWithdraw amount msgConstructor =
--     Eth.call
--         Config.httpProviderUrl
--         (StakingContract.withdraw
--             Config.stakingContractAddress
--             (TokenValue.getEvmValue amount)
--         )
--         |> Task.attempt msgConstructor
-- callGetReward : (Result Http.Error () -> msg) -> Cmd msg
-- callGetReward msgConstructor =
--     Eth.call
--         Config.httpProviderUrl
--         (StakingContract.getReward
--             Config.stakingContractAddress
--         )
--         |> Task.attempt msgConstructor
-- callExit : (Result Http.Error () -> msg) -> Cmd msg
-- callExit msgConstructor =
--     Eth.call
--         Config.httpProviderUrl
--         (StakingContract.exit
--             Config.stakingContractAddress
--         )
--         |> Task.attempt msgConstructor


getUserStakingInfo : Address -> (Result Http.Error UserStakingInfo -> msg) -> Cmd msg
getUserStakingInfo userAddress msgConstructor =
    Eth.call
        Config.httpProviderUrl
        (StakingScripts.getData
            Config.stakingScriptsAddress
            Config.stakingContractAddress
            userAddress
        )
        |> Task.map bindingStructToUserStakingInfo
        |> Task.attempt msgConstructor


bindingStructToUserStakingInfo : StakingScripts.GetData -> UserStakingInfo
bindingStructToUserStakingInfo data =
    { unstaked = TokenValue.tokenValue data.availableBalance
    , allowance = TokenValue.tokenValue data.allowedBalance
    , staked = TokenValue.tokenValue data.stakedBalance
    , claimableRewards = TokenValue.tokenValue data.earned
    , rewardRate = TokenValue.tokenValue data.rewardRate
    , timestamp = TimeHelpers.secondsBigIntToPosixWithWarning data.timestamp
    }



-- getUnstakedBalance : Address -> (Result Http.Error TokenValue -> msg) -> Cmd msg
-- getUnstakedBalance address msgConstructor =
--     Eth.call
--         Config.httpProviderUrl
--         (ERC20.balanceOf
--             Config.stakingLiquidityContractAddress
--             address
--         )
--         |> Task.attempt
--             (Result.map TokenValue.tokenValue >> msgConstructor)
-- getStakedBalance : Address -> (Result Http.Error TokenValue -> msg) -> Cmd msg
-- getStakedBalance address msgConstructor =
--     Eth.call
--         Config.httpProviderUrl
--         (ERC20.balanceOf
--             Config.stakingContractAddress
--             address
--         )
--         |> Task.attempt
--             (Result.map TokenValue.tokenValue >> msgConstructor)
-- getAmountEarned : Address -> (Result Http.Error TokenValue -> msg) -> Cmd msg
-- getAmountEarned address msgConstructor =
--     Eth.call
--         Config.httpProviderUrl
--         (StakingContract.earned
--             Config.stakingContractAddress
--             address
--         )
--         |> Task.attempt
--             (Result.map TokenValue.tokenValue >> msgConstructor)
