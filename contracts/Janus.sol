// SPDX-License-Identifier: MITNFA
pragma solidity ^0.8.4;

import "./YieldCurve.sol";
import "./FunbugProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IYieldCurve {
    function getYield(uint256 _totalStaked) external view returns (uint256);
    function setSlope(uint256 _slope) external view returns (bool);
    function setIntercept(uint256 _intercept) external view returns (bool);
}

interface IFunbugProxy {
    function _mint(address _to, uint256 _amount) external payable;
    function _burn(uint256 _amount) external payable;
    function _transfer(address _to, uint256 _amount) external payable;
    function _approve(address _spender, uint256 _amount) external payable;
    function _transferFrom(address _from, address _to, uint256 _amount) external payable;
    function _allowance(address _owner, address _spender) external view returns (uint256);
    function _balanceOf(address _owner) external view returns (uint256);
    function _totalSupply() external view returns (uint256);
    function _name() external view returns (string memory);
    function _symbol() external view returns (string memory);
    function _decimals() external view returns (uint8);
    function _pause() external payable;
    function _unpause() external payable;
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) external;
}

/// @custom:security-contact bc@goatkeepers.sh
contract Janus is Ownable, YieldCurve, FunbugProxy {

    uint256 seedPrice;

    struct Faction {
        string name;
        uint8 id;
    }

    struct Tile {
        string name;
        uint256 totalStaked;
        uint256 rakeBlockNumber;
        uint8 id;
    }

    // @dev Tile ID => Staker Wallet => Staked Amount
    mapping (uint256 => mapping(address => uint256)) public Staked;
    // @dev Tile ID => Faction => Staked Amount
    mapping (uint256 => mapping(uint8 => uint256)) public StakedByFaction;
    // @dev Tile ID => Staker Wallets
    mapping (uint256 => address[]) public Stakers;
    // @dev Staker address => unclaimed yield
    mapping (address => uint256) public YieldAvailable;

    Tile[] public tiles;
    Faction[] public factions;

    constructor(uint256 _seedPrice) public {
        seedPrice = _seedPrice;
        factions.push(Faction("GOAT", 0), Faction("Imperial", 1), Faction("Sacred", 2), 
            Faction("Architect", 3), Faction("Conqueror", 4), Faction("Ascetic", 5), 
            Faction("Sun and Moon", 6), Faction("Unmentionable", 7));
    }

    function seedTile(string calldata _name, uint8 _id) public payable returns(bool) {
        require(msg.value >= seedPrice);
        require(!tileExists(_id));
        require(!tileExists(_name));
        tiles[_id] = Tile(_name, 0, _id);
        return true;
    }

    // this is currently continuous, need to make it periodic
    function claimYield(uint256 _tileId) public returns (bool) {
        require(tileExists(_tileId));

        uint256 playerProportion = Staked[_tileId][msg.sender] / tiles[_tileId].totalStaked;
        uint256 totalYield = IYieldCurve.getYield(tiles[_tileId].totalStaked);
        uint256 yield = totalYield * playerProportion;
        uint256 balance = YieldAvailable[msg.sender];
        uint256 totalSend = balance + yield;
        IFunbugProxy(this)._transfer(msg.sender, totalSend);
        YieldAvailable[msg.sender] = 0;
        
        // rake all yield (this is super inefficient but I'm in a rush)
        for (uint256 i = 0; i < Stakers[_tileId].length; i++) {
            uint256 stakerProportion = Staked[_tileId][Stakers[_tileId][i]] / tiles[_tileId].totalStaked;
            uint256 stakerYield = yield * stakerProportion;
            YieldAvailable[Stakers[_tileId][i]] += stakerYield;
        }

        return true;
    }

    function getPlayerFaction() public view returns (uint8) {
        return 0;
    }

    function approveFunbug(address _spender, uint256 _amount) public returns (bool) {
        IFunbugProxy(this)._approve(_spender, _amount);
        return true;
    }

    function stakeTile(uint256 _tileId, uint256 _stakeAmount) public payable returns (bool) {
        require(tileExists(_tileId));
        Staked[_tileId][msg.sender] = _stakeAmount;
        StakedByFaction[_tileId][getPlayerFaction()] += _stakeAmount;
        Stakers[_tileId].push(msg.sender);
        require(IFunbugProxy(this)._transferFrom(msg.sender, this, _stakeAmount), "Transfer Failed");
        return true;
    }

    function unstakeTile(uint256 _tileId) public returns (bool) {
        require(tileExists(_tileId));
        require(Staked[_tileId][msg.sender] > 0);
        uint256 unstakeAmount = Staked[_tileId][msg.sender];
        Staked[_tileId][msg.sender] = 0;
        StakedByFaction[_tileId][getPlayerFaction()] -= unstakeAmount;
        Stakers[_tileId].remove(msg.sender);
        require(IFunbugProxy(this)._transfer(this, unstakeAmount), "Unstake Failed");
        return true;
    }

    function tileExists(uint256 _tileId) public view returns (bool) {
        return tiles[_tileId].name != "";
    }
}
