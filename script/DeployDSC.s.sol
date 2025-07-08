// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title DeployDSC
 * @notice This script deploys the DecentralizedStableCoin system: the stablecoin, DSCEngine, and network config.
 * @dev Intended to be run via Foundry's `forge script` tooling with broadcasting enabled.
 */
contract DeployDSC is Script {
    /// @notice Addresses of collateral tokens supported by the engine.
    address[] public collateralTokens;

    /// @notice Corresponding price feeds for the collateral tokens.
    address[] public priceFeeds;

    /**
     * @notice Deploys the DecentralizedStableCoin, DSCEngine, and HelperConfig contracts.
     * @dev Also transfers ownership of the stablecoin to the engine after deployment.
     * @return stablecoin The deployed DecentralizedStableCoin contract.
     * @return engine The deployed DSCEngine contract.
     * @return config The HelperConfig contract instance.
     */
    function run() external returns(
        DecentralizedStableCoin stablecoin, 
        DSCEngine engine, 
        HelperConfig config
    ) {
        config = new HelperConfig();

        (
            address wethUsdFeed, 
            address wbtcUsdFeed, 
            address weth, 
            address wbtc, 
            uint256 deployerKey
        ) = config.activeNetworkConfig();

        collateralTokens = [weth, wbtc];
        priceFeeds = [wethUsdFeed, wbtcUsdFeed];

        vm.startBroadcast(deployerKey);
        stablecoin = new DecentralizedStableCoin();
        engine = new DSCEngine(collateralTokens, priceFeeds, address(stablecoin));
        stablecoin.transferOwnership(address(engine));
        vm.stopBroadcast();

        return (stablecoin, engine, config);
    }
}
