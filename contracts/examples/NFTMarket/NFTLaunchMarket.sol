// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
<<<<<<< Updated upstream:contracts/examples/NFTMarket/NFTSaleMarket.sol
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // replace with custom implementation
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
=======
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol"; // replace with custom implementation
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol"; // replace with custom implementation
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
>>>>>>> Stashed changes:contracts/examples/NFTMarket/NFTLaunchMarket.sol
import "../../base/Market.sol";

/**
 * @dev Foundation of a market standard.
 */
<<<<<<< Updated upstream:contracts/examples/NFTMarket/NFTSaleMarket.sol
contract NFTSaleMarket is Market, ERC721EnumerableUpgradeable {
=======
contract NFTLaunchMarket is Initializable, Market, ERC721EnumerableUpgradeable {
    uint256 private count;
>>>>>>> Stashed changes:contracts/examples/NFTMarket/NFTLaunchMarket.sol
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

    function initialize(string calldata _symbol, string calldata _name)
        public
        virtual
        override
        initializer
    {
        __ERC721_init_unchained(_name, _symbol);
        __ERC721Enumerable_init_unchained();
        setMarketSymbol(_symbol);
        setMarketName(_name);
        owner = tx.origin;
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(ADMIN_ROLE, tx.origin);

        emit Establish(_symbol, _name, owner);
    }

    function setBaseURI(string calldata baseURI) external isAdmin {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMaxPerOwner(uint256 _maxPerOwner) public isAdmin {
        maxPerOwner = _maxPerOwner;
    }

    function setCatalogUri(string calldata _catalogUri)
        external
        override
        isAdmin
    {
        catalogUri = _catalogUri;
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
    {
        Product memory product = _catalog[productCode];

        require(quantity > 0, "invalid quantity");
        require(product.quantity > 0, "product oos");
        require(product.quantity >= quantity, "insufficient stock");
        require(quantity * product.price <= msg.value, "insufficient funds");

        _safeMint(msg.sender, quantity);
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
