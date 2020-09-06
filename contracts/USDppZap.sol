pragma solidity 0.6.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, SafeMath} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract USDppZap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint constant MAX = uint(-1);

    ICurve public susd;
    ICurve public y;
    IPSmartPool public usdpp;

    address[] tokens;

    constructor(
       ICurve _susd, 
       ICurve _y,
       IPSmartPool _usdpp
    ) public {
        susd = _susd;
        y = _y;
        usdpp = _usdpp;
        tokens = _usdpp.getTokens();
        approvals();
    }
    
    function joinPool(uint256 amount, uint256 index, uint256 maxIn, bool donateDust) external {
        // returns USDC > DAI > TUSD > sUSD
        (,uint256[] memory amounts) = usdpp.calcTokensForAmount(amount);
        IERC20(tokens[index]).safeTransferFrom(msg.sender, address(this), maxIn);

        // Swap order is USDC > TUSD > DAI > sUSD
        // Keep what is required and swap the rest for next
        uint256 i = index;
        uint dx;
        uint8 k = 3;
        while(k-- > 0) {
            dx = IERC20(tokens[i]).balanceOf(address(this)).sub(amounts[i]);
            if (i == 0) { // Swap USDC to TUSD
                i = 2;
                y.exchange_underlying(int128(1), int128(3), dx, amounts[i]);
            } else if (i == 1) { // Swap DAI to sUSD
                i = 3;
                susd.exchange(int128(0), int128(3), dx, amounts[i]);
            } else if (i == 2) { // Swap TUSD to DAI
                i = 1;
                y.exchange_underlying(int128(3), int128(0), dx, amounts[i]);
            } else { // swap sUSD > USDC
                i = 0;
                susd.exchange(int128(3), int128(1), dx, amounts[i]);
            }
        }
        usdpp.joinPool(amount);
        IERC20(address(usdpp)).safeTransfer(msg.sender, amount);
        if (!donateDust) {
            // If the user doesn't donate dust, they'll get back the change in form of a different coin
            // e.g. if user mints with DAI, dust will be in TUSD, lol
            IERC20(tokens[i]).safeTransfer(msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
        }
    }

    // risky (bancor hack)
    function approvals() public {
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.safeApprove(address(susd), 0);
            token.safeApprove(address(susd), MAX);
            token.safeApprove(address(y), 0);
            token.safeApprove(address(y), MAX);
            token.safeApprove(address(usdpp), 0);
            token.safeApprove(address(usdpp), MAX);
        }

    }
}

interface IPSmartPool is IERC20 {
  function joinPool(uint256 _amount) external;

  function exitPool(uint256 _amount) external;

  function getController() external view returns (address);

  function getTokens() external view returns (address[] memory);

  function calcTokensForAmount(uint256 _amount)
    external
    view
    returns (address[] memory tokens, uint256[] memory amounts);
}

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}