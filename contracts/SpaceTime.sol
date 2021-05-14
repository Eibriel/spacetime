// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {NativeMetaTransaction} from "./NativeMetaTransaction.sol";
import {ContextMixin} from "./ContextMixin.sol";

//import { SoapPunkCollectiblesChild } from "./SoupPunk_child.sol";

contract SpaceTime is
    ERC721PresetMinterPauserAutoIdUpgradeable,
    NativeMetaTransaction,
    ContextMixin
{
    using SafeMathUpgradeable for uint256;

    uint256 private _tokenCount;
    uint256 private _endTime;
    //
    uint256 private _multPrice;
    uint256 private _refundByCatch;
    //
    uint8 private _maxVotes;
    uint8 private _maxMintByAccount;
    //
    uint16 private _totalArtworkAmount;
    uint32 private _totalTokenAmount;
    //
    string private _contractURI;

    SoapPunkCollectiblesChild private _spContract;

    // Mapping from address to vote count
    mapping (address => uint8) private _accountVoteCount;

    // Mapping from address to amount of mints
    mapping (address => uint8) private _accountMintCount;

    // Mapping from token id to minter
    mapping (uint256 => address) private _artworkMinterAccount;

    // Mapping from token id to boolean -> true if arwork is minted
    mapping (uint256 => bool) private _artworkMinted;

    // Mapping from address to votes array
    mapping (address => uint256[10]) private _accountVoteArtwork;

    // Mapping from address to boolean -> true if refund was used
    mapping (address => bool) private _accountRefundUsed;

    IERC20 private _tokenERC20;


    function initialize(string memory name, string memory symbol, string memory baseURI, string memory domainSeparator) initializer public {
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseURI);

        _initializeEIP712(domainSeparator);
        _tokenCount = 0;

        uint256 _startTime = block.timestamp;
        setEndTime(_startTime.add(2592000));
        setPrice(5000000000000000000); // 5 Matic



        setContractURI("ipfs://contract-metadata");
    }


    /**
    * @dev the URL to a JSON file with contract metadata for OpenSea.
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
    * @dev Returns the address of the current owner, OpenSea uses this information.
    */
    function owner() public view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
    * @dev Returns information about the fees for a given token.
    */
    function royaltyInfo(uint256 _tokenId, uint256 _value) external view override returns (address receiver, uint256 amount) {
        return (address(this), _value.div(100);
    }

    function setERC20(IERC20 token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SpaceTime: must have admin role to set token");

        _tokenERC20 = token;
    }

    function setBaseURI(string memory baseURI, uint256 id) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SpaceTime: must have admin role to change uri");

        _setBaseURI(baseURI);
    }

    function setContractURI(string memory __contractURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SpaceTime: must have admin role to change contract uri");

        _contractURI = __contractURI;

        ContractURISet(__contractURI);
    }

    function setPrice(uint256 multPrice) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SpaceTime: must have admin role to set price");

        _multPrice = multPrice;

        emit PriceSet(multPrice);
    }

    function setEndTime(uint256 endTime) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SpaceTime: must have admin role to change end time");

        _endTime = endTime;

        emit EndTimeSet(endTime);
    }

    function mint(address to) public override {
        require(false, "SpaceTime: mint is not allowed");
        // Nobody can call mint()
    }

    function getPrice(address for_account) public view returns(uint256 price, bool use_refund) {
        //
        bool willUseRefund = false;
        // If user didn't used the refund
        if (!_accountRefundUsed[for_account]) {
            // Check if owns Soaps
            if (_spContract.balanceOf(for_account, 0)>0) {
                willUseRefund = true;
            } else {
                // Iterate over votes
                for (uint i=0; i<_accountVoteCount[for_account]; i++) {
                    if (_artworkMinterAccount[_accountVoteArtwork[for_account][i]] == for_account) {
                        continue;
                    }
                    // If the voted artwork was minted
                    if (_artworkMinted[_accountVoteArtwork[for_account][i]]) {
                        willUseRefund = true;
                        break;
                    }
                }
            }
        }
        //
        uint256 tmpPrice = _multPrice.mul(5000);
        if (_tokenCount < 400) {
            tmpPrice = _multPrice.mul(10);
        } else if (_tokenCount < 800) {
            tmpPrice = _multPrice.mul(25);
        } else if (_tokenCount < 950) {
            tmpPrice = _multPrice.mul(45);
        } else if (_tokenCount < 990) {
            tmpPrice = _multPrice.mul(85);
        } else if (_tokenCount < 1024) {
            tmpPrice = _multPrice.mul(150);
        }
        if (!willUseRefund) {
            // Price not cut in half
            tmpPrice = tmpPrice.mul(2);
        }
        //
        return (tmpPrice, willUseRefund);
    }


    /**
    * @dev Get price, setting the refund as used.
    */
    function _getPrice() private returns(uint256 price) {
        (uint256 tmpPrice, bool willUseRefund) = getPrice(_msgSender());

        // Mark refund as used
        if (willUseRefund) {
            _accountRefundUsed[_msgSender()] = true;
        }

        return tmpPrice;
    }


    /**
    * @dev Mints artwork on sale.
    */
    function buy()
        external
        //payable
        price(_getPrice())
        returns(uint256 index)
    {
        require(!paused(), "SpaceTime: token mint while paused");

        _tokenCount = _tokenCount.add(1);

        _artworkMinterAccount[id] = _msgSender();

        _artworkMinted[id] = true;

        _accountMintCount[_msgSender()] += 1;

        _mint(_msgSender(), _tokenCount-1);

        return _tokenCount-1;
    }


    /*
    * @dev Remove all Ether from the contract, and transfer it to account of owner
    */
    function withdrawBalance() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SpaceTime: must have admin role to withdraw");
        uint256 balance = _tokenERC20.balanceOf(address(this));
        _tokenERC20.transfer(_msgSender(), balance);

        emit Withdraw(balance);
    }


    // Modifiers


    /**
    * @dev modifier Associete fee with a function call. If the caller sent too much, then is refunded, but only after the function body.
    * This was dangerous before Solidity version 0.4.0, where it was possible to skip the part after `_;`.
    * @param _amount - ether needed to call the function
    */
    modifier price(uint256 _amount) {
        require(_tokenERC20.balanceOf(_msgSender()) >= _amount, "SpaceTime: Not enough ERC20 tokens.");
        require(_tokenERC20.allowance(_msgSender(), address(this)) >= _amount, "SpaceTime: Not enough ERC20 token allowance.");

        _;

        _tokenERC20.transferFrom(_msgSender(), address(this), _amount);
    }


    // Events


    /**
    * @dev Emits when owner take ETH out of contract
    * @param balance - amount of ETh sent out from contract
    */
    event Withdraw(uint256 balance);

    /**
    * @dev Emits when a new price is set
    * @param multPrice - a multiplier for the price
    */
    event PriceSet(uint256 multPrice);

    /**
    * @dev Emits when an artwork is voted
    * @param id - an artwork id
    * @param account - an account address
    */
    event Vote(uint256 id, address account);

    /**
    * @dev Emits when the SoapPunk contract address is set
    * @param spAddress - an address
    */
    event SPAddressSet(address spAddress);

    /**
    * @dev Emits when the contract URI is set
    * @param contractURI - an URL to the metadata
    */
    event ContractURISet(string contractURI);

    /**
    * @dev Emits when the end time is set
    * @param endTime - the event end time
    */
    event EndTimeSet(uint256 endTime);


    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        override
        view
        returns (address payable sender)
        {
            return ContextMixin.msgSender();
    }
}
