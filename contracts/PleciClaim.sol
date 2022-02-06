// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PleciClaim is Ownable, ERC1155("") {
    using Counters for Counters.Counter;
    Counters.Counter private id;

    struct Claim {
        address contractToken;
        uint256 amountToken;
        uint256 totalAmountToken;
    }

    mapping(uint256 => Claim) public claimData;

    event MintPleci(address indexed minter, uint256 id, uint256 amount, uint256 amountToken);
    event ClaimPleci(address indexed who, uint256 id, uint256 amount, uint256 amountToken);

    constructor() {
        id.increment();
    }

    function customURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function mint(address to_, address contractToken_, uint256 totalAmountToken, uint256 amount_, bytes memory data_) external payable {
        uint256 amountToken = contractToken_ == address(0) ? msg.value / amount_ : totalAmountToken * amount_;
        require(contractToken_ != address(0) && msg.value > 0, "Ether must be zero");
        require(amountToken > 0, "Amount cannot be zero");
        address minter = _msgSender();
        uint256 idCurrent = id.current();
        claimData[idCurrent] = Claim(contractToken_, amountToken, totalAmountToken);
        if (contractToken_ != address(0)) {
            IERC20(contractToken_).transferFrom(minter, address(this), totalAmountToken);
        }
        _mint(to_, idCurrent, amount_, data_);
        id.increment();
        emit MintPleci(minter, idCurrent, amount_, totalAmountToken);
    }

    function claim(uint256 id_, uint256 amount_) external {
        address who = _msgSender();
        Claim memory data = claimData[id_];
        uint256 totalAmount = data.amountToken * amount_;
        _burn(who, id_, amount_);
        if (data.contractToken == address(0)) {
            payable(who).transfer(totalAmount);
        } else {
            IERC20(data.contractToken).transferFrom(address(this), who, totalAmount);
        }
        emit ClaimPleci(who, id_, amount_, totalAmount);
    }
}