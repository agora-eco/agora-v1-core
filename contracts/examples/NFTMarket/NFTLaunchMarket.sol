// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol"; // replace with custom implementation
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol"; // replace with custom implementation
import "./INFTLaunchMarket.sol";
import "../../base/Market.sol";

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
contract NFTLaunchMarket is
    Initializable,
    Market,
    ERC721EnumerableUpgradeable,
    INFTLaunchMarket
{
    uint256 private count;
    uint256 public maxPerOwner;
    string private _baseTokenURI;

    modifier guard(string memory productCode, uint256 quantity) {
        require(msg.sender == tx.origin, "Request cannot be proxied");
        require(
            balanceOf(tx.origin) + quantity <= maxPerOwner,
            "Exceeds maxPerOwner"
        );
        _;
    }

    function initialize(
        string memory _symbol,
        string memory _name,
        uint256 _maxPerOwner
    ) public virtual initializer {
        __NFTLaunchMarket_init(_symbol, _name, _maxPerOwner);
    }

    function __NFTLaunchMarket_init(
        string memory _symbol,
        string memory _name,
        uint256 _maxPerOwner
    ) internal initializer {
        __AccessControl_init_unchained();
        __ERC721_init_unchained(_name, _symbol);
        __ERC721Enumerable_init_unchained();
        __Market_init_unchained(_symbol, _name);
        __NFTLaunchMarket_init_unchained(_maxPerOwner);
        /* setMarketSymbol(_symbol);
        setMarketName(_name);
        owner = tx.origin;
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(ADMIN_ROLE, tx.origin); */
    }

    function __NFTLaunchMarket_init_unchained(uint256 _maxPerOwner)
        internal
        initializer
    {
        maxPerOwner = _maxPerOwner;
    }

    function setBaseURI(string calldata baseURI) external isAdmin {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMaxPerOwner(uint256 _maxPerOwner)
        external
        virtual
        override
        isAdmin
    {
        maxPerOwner = _maxPerOwner;
    }

    /**
     * @dev See {IMarket-purchase}
     */
    function purchase(string calldata productCode, uint256 quantity)
        external
        payable
        virtual
        override
        productExist(productCode)
        isActive
        guard(productCode, quantity)
    {
        Product memory product = _catalog[productCode];

        require(quantity > 0, "invalid quantity");
        require(product.quantity > 0, "product oos");
        require(product.quantity >= quantity, "insufficient stock");
        require(quantity * product.price <= msg.value, "insufficient funds");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, count + i);
        }

        count += quantity;
        product.quantity -= quantity;
        _catalog[productCode] = product;

        emit Purchase(
            productCode,
            product.name,
            quantity,
            product.price * quantity,
            _msgSender()
        );
        //payable(owner).transfer(product.price);
    }

    /* function mint(string calldata productCode, uint256 quantity)
        productExist(productCode)
        guard(productCode, quantity)
    {
        purchase(productCode, quantity);
    } */

    function withdraw(address target, uint256 amount) external isAdmin {
        payable(target).transfer(amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[48] private __gap;
}
