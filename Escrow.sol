// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Escrow {
    address public escrow_admin;
    address public sender;
    address public receiver;
    uint256 public depositAmount;
    uint256 public releaseTime;
    uint256 public releaseTimeBuffer;
    bool public fundsReleased;

    event FundsDeposited(address indexed sender, uint256 amount, uint256 releaseTime);
    event FundReleased(address indexed receiver, uint256 amount);

    modifier fundsNotReleased() {
        require(!fundsReleased, "Funds have already been released");
        _;
    }

    constructor(address _receiver, uint256 _releaseTimeInDays) {
        escrow_admin = msg.sender;
        sender = address(0);
        receiver = _receiver;
        depositAmount = 0;
        releaseTimeBuffer = _releaseTimeInDays * 24 * 60 * 60 ;
        releaseTime = block.timestamp + _releaseTimeInDays ;
        
    }

    function depositFunds() external payable fundsNotReleased {

        require(depositAmount == 0, "Fund has already been deposited into the contract");
        require(msg.value > 0, "Deposit amount must be greater than 0");

        sender = msg.sender;
        depositAmount = msg.value;
        releaseTime = block.timestamp + releaseTimeBuffer;
        emit FundsDeposited(msg.sender, msg.value, releaseTime);
    }

    function releaseFunds() external fundsNotReleased {

        require(msg.sender == receiver, "Only predefined receiver(Bob) can call this function");
        require(block.timestamp >= releaseTime, "Funds cannot be released before the release time");
        require(depositAmount > 0, "No funds to release");

        (bool success, ) = payable(receiver).call{value: depositAmount}("");
        require(success, "Failed to release funds to receiver(Bob).");

        fundsReleased = true;
        emit FundReleased(receiver, depositAmount);
    }

    // Additional function to allow Alice to withdraw funds if needed
    function withdrawFunds() external fundsNotReleased {

        require((msg.sender == escrow_admin) || (msg.sender == sender), "Only the creator of the escrow contract or sender(Alice) can call this function");
        require(block.timestamp >= releaseTime, "Funds cannot be withdrawn before the release time");
        require(depositAmount > 0, "No funds to withdraw");

        (bool success, ) = payable(sender).call{value: depositAmount}("");
        require(success, "Failed to withdraw funds to sender(Alice).");

        fundsReleased = true;
        emit FundReleased(sender, depositAmount);
    }
    
}