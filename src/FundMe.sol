// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts.git/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 private constant MINIMUM_USD = 5 * 1e18;

    AggregatorV3Interface private immutable s_priceFeed;
    address private immutable i_owner;
    address[] private s_funders;
    uint256 private s_amountRaised;
    mapping(address => uint256) private s_funderToAmount;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Fund has to be at least 5 USD worth of ETH."
        );
        s_funders.push(msg.sender);
        s_funderToAmount[msg.sender] += msg.value;
        s_amountRaised += msg.value;
    }

    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 i = 0; i < fundersLength; i++) {
            s_funderToAmount[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        s_amountRaised = 0;

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getMinimumUsd() public pure returns (uint256) {
        return MINIMUM_USD;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAmountFunded(
        address funderAddress
    ) public view returns (uint256) {
        return s_funderToAmount[funderAddress];
    }
}
