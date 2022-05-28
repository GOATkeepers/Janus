// SPDX-License-Identifier: MITNFA
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

// @notice: the simplest bonding curve u ever did see 🥹🥹
// @dev: given a total staked supply of _x_, return a yield distribution of _y_
/// @custom:security-contact bc@goatkeepers.sh
contract YieldCurve is Ownable {

    uint256 slope;
    uint256 intercept;
    uint8 curveInvertor;

    constructor(uint256 _slope, uint256 _intercept) public {
        slope = _slope;
        intercept = _intercept;
    }

    function getYield(uint256 _totalStaked) public view returns (uint256) {
        return slope * ((_totalStaked * curveInvertor) ** 2) + intercept + _totalStaked;
    }

    function setSlope(uint256 _slope) public onlyOwner returns (bool) {
        slope = _slope;
        return true;
    }

    function setIntercept(uint256 _intercept) public onlyOwner returns (bool) {
        intercept = _intercept;
        return true;
    }
}
