pragma solidity ^0.8.0;

contract Auction {
    address payable public beneficiary;
    uint256 public auctionEndTime;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) pendingReturns;

    bool ended = false;

    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(
        uint256 biddingTime,
        address payable auctionBeneficiary
    ) {
        beneficiary = auctionBeneficiary;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() public payable {
        require(
            block.timestamp <= auctionEndTime,
            "Auction has already ended."
        );
        require(
            msg.value > highestBid,
            "There is already a higher bid."
        );

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        require(!ended, "Auction has already ended.");
        require(
            block.timestamp >= auctionEndTime,
            "Auction has not yet ended."
        );

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}
