// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

/**
 * @title HelperConfig
 * @notice Provides environment-specific configuration (Sepolia or local Anvil) for deployment scripts.
 * @dev Determines and exposes network-specific price feeds, mock tokens, and deployer key.
 */
contract HelperConfig is Script {
    /// @notice Struct representing configuration parameters for a given network
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    /// @notice The active network configuration used during deployment.
    NetworkConfig public activeNetworkConfig;

    /// @notice Number of decimals used by the mock price feeds.
    uint8 public constant DECIMALS = 8;

    /// @notice Mock ETH/USD price used on local Anvil chain.
    int256 public constant ETH_USD_PRICE = 2000e8;

    /// @notice Mock BTC/USD price used on local Anvil chain.
    int256 public constant BTC_USD_PRICE = 1000e8;

    /// @notice Default private key used for local Anvil deployments.
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    /**
     * @notice Constructor selects the appropriate network configuration based on 'block.chainid'.
     * @dev Chooses Sepolia config if on chain ID 11155111; otherwise creates a new Anvil config.
     */
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    /**
     * @notice Returns hardcoded configuration for Sepolia network.
     * @dev Uses live Chainlink price feeds and deployed ERC20 tokens.
     * @return config The Sepolia network configuration.
     */
    function getSepoliaEthConfig() public view returns(NetworkConfig memory config) {
        config = NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, 
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    /**
     * @notice Deploys and returns configuration for local Anvil chain.
     * @dev If mocks are already deployed, reuses existing config.
     * @return config The local (Anvil) network configuration with mocks.
     */
    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory config) {
        if(activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            BTC_USD_PRICE
        );
        ERC20Mock wbtcMock = new ERC20Mock("WBTC", "WBTC", msg.sender, 1000e8);
        vm.stopBroadcast();

        config = NetworkConfig({
            wethUsdPriceFeed: address(ethUsdPriceFeed),
            wbtcUsdPriceFeed: address(btcUsdPriceFeed),
            weth: address(wethMock),
            wbtc: address(wbtcMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
