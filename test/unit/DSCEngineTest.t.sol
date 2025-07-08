 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant HALF_AMOUNT_COLLATERAL = 5 ether;
    uint256 public constant ETH_AMOUNT_IN_WEI = 15 ether;
    uint256 public constant DSC_AMOUNT = 50 ether;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount);

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run(); 
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, AMOUNT_COLLATERAL);
        ERC20Mock(wbtc).mint(USER, AMOUNT_COLLATERAL);
    }

    // --- Utilities ---

    modifier asUser() {
        vm.startPrank(USER);
        _;
        vm.stopPrank();
    }

    function approveAndDeposit(address token, uint256 amount) internal asUser {
        ERC20Mock(token).approve(address(dsce), amount);
        dsce.depositCollateral(token, amount);
    }

    // --- Constructor Tests ---

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

        function testConstructorSetsCorrectPriceFeed() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);

        DSCEngine testEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        assertEq(testEngine.getCollateralTokenPriceFeed(tokenAddresses[0]), priceFeedAddresses[0]);
    }

    // --- Price Tests ---

    function testGetUsdValue() public view {
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ETH_AMOUNT_IN_WEI);
        assertEq(actualUsd, expectedUsd);
    }

    function testGetUsdValueRevertsWithUnapprovedToken() public {
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dsce.getUsdValue(address(0),  ETH_AMOUNT_IN_WEI);
    }

    function testGetTokenAmountFromUsdRevertsWithUnapprovedToken() public {
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dsce.getTokenAmountFromUsd(address(0), ETH_AMOUNT_IN_WEI);
    }

    function testGetTokenAmountFromUsdReturnsCorrectAmount() public view {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(actualWeth, expectedWeth);
    }

    function testGetUsdValueReturnsZeroIfAmountIsZero() public view {
        assertEq(dsce.getUsdValue(weth, 0), 0);
    }

    function testGetTokenAmountFromUsdReturnsZeroIfUsdAmountIsZero() public view {
        assertEq(dsce.getTokenAmountFromUsd(weth, 0), 0);
    }

    // --- depositCollateral Tests ---

    function testDepositRevertsIfAmountIsZero() public asUser {
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
    }

    function testDepositRevertsForUnapprovedToken() public asUser {
        ERC20Mock randomToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dsce.depositCollateral(address(randomToken), AMOUNT_COLLATERAL);
    }

    function testDepositRevertsIfNoApproval() public asUser {
        vm.expectRevert(DSCEngine.DSCEngine__InsufficientAllowance.selector);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
    }

    function testCanDepositAndGetAccountInfo() public {
        approveAndDeposit(weth, AMOUNT_COLLATERAL);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        
        assertEq(totalDscMinted, 0);
        assertEq(collateralValueInUsd, dsce.getUsdValue(weth, AMOUNT_COLLATERAL));
    }

    function testSuccessfulDepositWithMultipleAllowedTokens() public asUser {
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        assertEq(dsce.getAccountCollateralDeposit(USER, weth), AMOUNT_COLLATERAL);

        ERC20Mock(wbtc).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(wbtc, AMOUNT_COLLATERAL);
        assertEq(dsce.getAccountCollateralDeposit(USER, wbtc), AMOUNT_COLLATERAL);
    }

    function testRepeatDepositAccumulatesCollateralCorrectly() public asUser {
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, HALF_AMOUNT_COLLATERAL);
        assertEq(dsce.getAccountCollateralDeposit(USER, weth), HALF_AMOUNT_COLLATERAL);

        dsce.depositCollateral(weth, HALF_AMOUNT_COLLATERAL);
        assertEq(dsce.getAccountCollateralDeposit(USER, weth), AMOUNT_COLLATERAL);
    }

    // --- Events ---

    function testEmitCollateralDepositedEventOnDeposit() public asUser {
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        vm.expectEmit(true, true, true, true);
        emit CollateralDeposited(USER, weth, AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
    }

    function testEmitCollateralRedeemedEventOnRedeem() public asUser {
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        dsce.mintDsc(DSC_AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit CollateralRedeemed(USER, USER, weth, 5 * 1e18);

        dsce.redeemCollateral(weth, 5 * 1e18);
    }
}