// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "hardhat/console.sol";

import "./Market.sol";

contract MarketFactory {
    using Strings for string;

    address public paymentProxyAddress;
    //address[] public markets;
    mapping(uint256 => address) public markets;
    mapping(address => uint256) public marketRegistry;
    /* mapping(address => bool) internal _registered;
    mapping(address => bool) internal _verified;
    mapping(string => UpgradeableBeacon) internal _extensionRegistry; */
    mapping(uint256 => ExtensionEntry) internal _extensionRegistry;

    uint256 private _extensionCount;
    uint256 private _marketCount;

    struct ExtensionEntry {
        bool exists;
        string name;
        uint256 state; // 0: APPROVING 1: REGISTERED 2: VERIFIED
        UpgradeableBeacon proxy;
    }

    struct MarketEntry {
        bool exists;
        address location;
        address owner;
        uint256 extensionId;
    }

    event AddExtension(
        uint256 extensionId,
        string extensionName,
        address indexed logic,
        address indexed deployer
    );

    event UpgradeExtension(uint256 extensionId, address indexed logic);

    event PushExtension(uint256 extensionId, uint256 state);

    event DeployMarket(
        uint256 extensionId,
        bytes data,
        address indexed proxy,
        address indexed deployer
    );

    modifier extensionExists(uint256 extensionId) {
        require(
            _extensionRegistry[extensionId].exists == true,
            "MarketFactory: extension DNE"
        );
        _;
    }

    constructor(address _paymentProxyAddress) {
        paymentProxyAddress = _paymentProxyAddress;
    }

    function addExtension(string calldata extensionName, address logic)
        external
        returns (uint256)
    {
        _extensionRegistry[_extensionCount] = ExtensionEntry(
            true,
            extensionName,
            0,
            new UpgradeableBeacon(logic)
        );
        _extensionCount += 1;

        emit AddExtension(
            _extensionCount - 1,
            extensionName,
            logic,
            msg.sender
        );
        return _extensionCount - 1;
        //_extensionRegistry[extensionName] = new UpgradeableBeacon(logic);
        //emit AddExtension(extensionName, logic, msg.sender);
    }

    function upgradeExtension(uint256 extensionId, address logic)
        external
        extensionExists(extensionId)
    {
        _extensionRegistry[extensionId].proxy.upgradeTo(logic);
        emit UpgradeExtension(extensionId, logic);
        //address oldLogic = address(_extensionRegistry[extensionName]);
        //_extensionRegistry[extensionName].upgradeTo(logic);
        //emit UpgradeExtension(extensionName, oldLogic, logic);
    }

    function pushExtension(uint256 extensionId, uint256 state)
        external
        extensionExists(extensionId)
    {
        _extensionRegistry[extensionId].state = state;
        emit PushExtension(extensionId, state);
    }

    function deployMarket(uint256 extensionId, bytes calldata data)
        external
        extensionExists(extensionId)
        returns (address)
    {
        BeaconProxy proxy = new BeaconProxy(
            address(_extensionRegistry[extensionId].proxy),
            data
        );
        address proxyAddress = address(proxy);

        markets[_marketCount] = proxyAddress;
        _marketCount += 1;
        marketRegistry[proxyAddress] = extensionId;
        //_registered[proxyAddress] = true;

        emit DeployMarket(extensionId, data, proxyAddress, msg.sender);
        /* emit DeployMarket(
            msg.sender,
            extensionName,
            address(_extensionRegistry[extensionName]),
            data,
            proxyAddress
        ); */
        return proxyAddress;
    }

    function disableMarket(address _market) public {
        // update market to disable. irreversible
        // only market owner can disable
        //market.disable(true);
    }

    function verify(address _market, bool _state) public {
        // must be admin
        // emit
    }
}
