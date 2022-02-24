// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INativeToken.sol";
import "./ITokenTransferProxy.sol";
import "../../base/Market.sol";

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
contract NativeTokenMarket is Initializable, Market, INativeToken {
    uint256 private _maxPerOwner;
    uint256 private _maxSupply;
    IERC20 private _token;
    ITokenTransferProxy private _tokenTransferProxy;

    modifier guard(string memory productCode, uint256 quantity) {
        require(msg.sender == tx.origin, "Request cannot be proxied");
        _;
    }

    function initialize(
        string memory _symbol,
        string memory _name,
        IERC20 token_,
        ITokenTransferProxy tokenTransferProxy_
    ) public virtual initializer {
        __NativeTokenMarket_init(_symbol, _name, token_, tokenTransferProxy_);
    }

    function __NativeTokenMarket_init(
        string memory _symbol,
        string memory _name,
        IERC20 token_,
        ITokenTransferProxy tokenTransferProxy_
    ) internal initializer {
        __AccessControl_init_unchained();
        __Market_init_unchained(_symbol, _name);
        __NativeTokenMarket_init_unchained(token_, tokenTransferProxy_);
    }

    function __NativeTokenMarket_init_unchained(
        IERC20 token_,
        ITokenTransferProxy tokenTransferProxy_
    ) internal initializer {
        _token = token_;
        _tokenTransferProxy = tokenTransferProxy_;
    }

    function setToken(IERC20 token_) external virtual override isAdmin {
        _token = token_;
    }

    function setTokenTransferProxy(ITokenTransferProxy tokenTransferProxy_)
        external
        virtual
        override
        isAdmin
    {
        _tokenTransferProxy = tokenTransferProxy_;
    }

    function token() external view virtual override returns (IERC20) {
        return _token;
    }

    function tokenTransferProxy()
        external
        view
        virtual
        override
        returns (ITokenTransferProxy)
    {
        return _tokenTransferProxy;
    }

    function approveProxySpending() external virtual override {
        _tokenTransferProxy.approve(_token);
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
        require(
            quantity * product.price <=
                _token.allowance(_msgSender(), address(this)),
            "insufficient allowance"
        );

        _token.transferFrom(
            _msgSender(),
            address(this),
            quantity * product.price
        );

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
