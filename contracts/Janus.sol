// SPDX-License-Identifier: MITNFA
pragma solidity ^0.8.4;

import "./YieldCurve.sol";
import "./FunbugProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IYieldCurve {
    function getYield(uint256 _totalStaked) external view returns (uint256);
}

interface ISteward {
    function mint(address to) external;
}

// 1 getFaction finish

interface IFunbugProxy {
    function _transfer(address _to, uint256 _amount) external payable;
    function _approve(address _spender, uint256 _amount) external payable;
    function _transferFrom(address _from, address _to, uint256 _amount) external payable;
}

/// @custom:security-contact bc@goatkeepers.sh
contract Janus is Ownable, YieldCurve, FunbugProxy {

    string[] public factionSeed = ["GOAT", "Imperial", "Sacred", "Architect", 
        "Conqueror", "Ascetic", "Sun and Moon", "Unmentionable"];
    uint256 public seedPrice;
    uint256 public playerCharacterPrice;
    address public FunbugProxyAddress;
    address public StewardAddress;
    address public YieldCurveAddress;

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
    // @dev Urbit Holders get a faction based on their star
    mapping (address => mapping(bool => uint8)) public urbitFaction;

    Tile[] public tiles;
    Faction[] public factions;

    constructor(uint256 _seedPrice, uint256 _playerCharacterPrice) {
        seedPrice = _seedPrice;
        playerCharacterPrice = _playerCharacterPrice;
        for (uint8 i = 0; i < factionSeed.length; i++) {
            factions.push(Faction(factionSeed[i], i));
        }
    }

    function createPlayerCharacter(uint256 urbitId) public payable {
        require(msg.value >= playerCharacterPrice, 'HFSP');
        if (urbitId != 0) {
            bytes32 PCFactionSeed = bytes32(urbitId);
            bytes1 urbitSlice = bytes1(PCFactionSeed[2]);
            uint8 urbitFactionId = uint8(urbitSlice);
            urbitFaction[msg.sender][true];
        }
    }

    function seedTile(string calldata _name, uint8 _id, address _FunbugProxyAddress, address _StewardAddress) public payable returns(bool) {
        require(msg.value >= seedPrice);
        require(!tileExists(_id));
        tiles[_id] = Tile(_name, 0, block.number, _id);
        return true;
    }

    // this is currently continuous, need to make it periodic
    function claimYield(uint256 _tileId) public returns (bool) {
        require(tileExists(_tileId));

        uint256 playerProportion = Staked[_tileId][msg.sender] / tiles[_tileId].totalStaked;
        uint256 totalYield = IYieldCurve(YieldCurveAddress).getYield(tiles[_tileId].totalStaked);
        uint256 yield = totalYield * playerProportion;
        uint256 balance = YieldAvailable[msg.sender];
        uint256 totalSend = balance + yield;
        IFunbugProxy(FunbugProxyAddress)._transfer(msg.sender, totalSend);
        YieldAvailable[msg.sender] = 0;
        
        // rake all yield (this is super inefficient but I'm in a rush)
        for (uint256 i = 0; i < Stakers[_tileId].length; i++) {
            // calculate yield HOURLY! BAGS HERE MOFOS
            if (block.number >= (tiles[_tileId].rakeBlockNumber + 900 )) {
                uint256 stakerProportion = Staked[_tileId][Stakers[_tileId][i]] / tiles[_tileId].totalStaked;
                uint256 stakerYield = yield * stakerProportion;
                YieldAvailable[Stakers[_tileId][i]] += stakerYield;
                return true;
            }
            else {
                return true;
            }
        }

        return true;
    }

    function getPlayerFaction() public view returns (uint8) {
        if (urbitFaction[msg.sender][true] != 0) {
            return urbitFaction[msg.sender][true];
        }
        else {
            return 0;
        }
    }

    function setPlayerCharacterPrice(uint256 _price) public {
        playerCharacterPrice = _price;
    }

    function setSeedPrice(uint256 _price) public {
        seedPrice = _price;
    }

    function approveFunbug(address _spender, uint256 _amount) public returns (bool) {
        IFunbugProxy(FunbugProxyAddress)._approve(_spender, _amount);
        return true;
    }

    function stakeTile(uint256 _tileId, uint256 _stakeAmount) public payable returns (bool) {
        require(tileExists(_tileId));
        Staked[_tileId][msg.sender] = _stakeAmount;
        StakedByFaction[_tileId][getPlayerFaction()] += _stakeAmount;
        Stakers[_tileId].push(msg.sender);
        IFunbugProxy(FunbugProxyAddress)._transferFrom(msg.sender, address(this), _stakeAmount);
        bool stakeSuccess = true;
        require(stakeSuccess == true, "Transfer Failed");
        return true;
    }

    function unstakeTile(uint256 _tileId) public returns (bool) {
        require(tileExists(_tileId));
        require(Staked[_tileId][msg.sender] > 0);
        uint256 unstakeAmount = Staked[_tileId][msg.sender];
        Staked[_tileId][msg.sender] = 0;
        StakedByFaction[_tileId][getPlayerFaction()] -= unstakeAmount;
        IFunbugProxy(FunbugProxyAddress)._transfer(address(this), unstakeAmount);
        bool unstakeSuccess = true;
        require(unstakeSuccess == true, "Unstake Failed");
        return true;
    }

    // expensive but dammit strict typing
    function tileExists(uint256 _tileId) public view returns (bool) {
        bytes32 name = keccak256(abi.encodePacked((tiles[_tileId].name)));
        return name != "";
    }
}
