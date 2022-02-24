// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ITokenSaleMarket.sol";
import "../../base/Market.sol";

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
contract TokenSaleMarket is
    Initializable,
    Market,
    ERC20Upgradeable,
    ITokenSaleMarket
{
    uint256 private _maxPerOwner;
    uint256 private _maxSupply;

    modifier guard(string memory productCode, uint256 quantity) {
        require(msg.sender == tx.origin, "Request cannot be proxied");
        require(
            _maxSupply == 0 || totalSupply() + quantity <= _maxSupply,
            "Exceeds maxSupply"
        );
        require(
            balanceOf(tx.origin) + quantity <= _maxPerOwner,
            "Exceeds maxPerOwner"
        );
        _;
    }

    function initialize(
        string memory _symbol,
        string memory _name,
        uint256 maxSupply_,
        uint256 maxPerOwner_
    ) public virtual initializer {
        __TokenSaleMarket_init(_symbol, _name, maxSupply_, maxPerOwner_);
    }

    function __TokenSaleMarket_init(
        string memory _symbol,
        string memory _name,
        uint256 maxSupply_,
        uint256 maxPerOwner_
    ) internal initializer {
        __AccessControl_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        __Market_init_unchained(_symbol, _name);
        __TokenSaleMarket_init_unchained(maxSupply_, maxPerOwner_);
    }

    function __TokenSaleMarket_init_unchained(
        uint256 maxSupply_,
        uint256 maxPerOwner_
    ) internal initializer {
        _maxSupply = maxSupply_;
        _maxPerOwner = maxPerOwner_;
    }

    function setMaxPerOwner(uint256 maxPerOwner_)
        external
        virtual
        override
        isAdmin
    {
        _maxPerOwner = maxPerOwner_;
    }

    function setMaxSupply(uint256 maxSupply_)
        external
        virtual
        override
        isAdmin
    {
        _maxSupply = maxSupply_;
    }

    function maxPerOwner() external view virtual override returns (uint256) {
        return _maxPerOwner;
    }

    function maxSupply() external view virtual override returns (uint256) {
        return _maxSupply;
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

        _mint(msg.sender, quantity);

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

    function withdraw(address target, uint256 amount) external isAdmin {
        payable(target).transfer(amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[48] private __gap;
}
