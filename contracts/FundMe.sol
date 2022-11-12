// get funds from users
// withdraw funds
// set a minimum funding value in USD

// SPDX-License-Identifier: MIT
// Pragma - style guide 01
pragma solidity ^0.8.8;

// Imports - style guide 02
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
import "hardhat/console.sol";

// saving on gas - constant and imutable

// Error Codes - style guide 02.5
error FundMe__NotOwner();

// Interfaces - style guide 03
// Libraries - style guide 04

// Contracts - style guide 05
// documentation comments
/** @title A contract for crowdfunding
 *  @author Dan Van Pelt
 *  @notice This contract is to demo a sample funding contract and is part of the Free Code Camp Blockchain course
 *  @dev This impliments price feeds as our library
 */
contract FundMe {
    // Type declarations - style guide 06
    using PriceConverter for uint256;

    // State variables - style guide 07
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    address private immutable i_owner;
    AggregatorV3Interface public s_priceFeed;

    // Events (we have none!) - style guide 08
    // Modifiers - style guide 09
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        //if (msg.sender != i_owner) revert("FundMe__NotOwner");
        _;
    }

    // Functions - style guide 10 - Order:
    //// constructor - 10.1
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //// receive - 10.2
    receive() external payable {
        fund();
    }

    //// fallback - 10.3
    fallback() external payable {
        fund();
    }

    //// external - 10.4
    //// public - 10.5
    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //console.log("Withdraw: funderIndex:");
            //console.log(funderIndex);
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the array
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory m_funders = s_funders;
        // mappings can't be in memory

        for (
            uint256 funderIndex = 0;
            funderIndex < m_funders.length;
            funderIndex++
        ) {
            //console.log("Withdraw: funderIndex:");
            //console.log(funderIndex);
            address funder = m_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the array
        s_funders = new address[](0);

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed");
    }

    //// internal - 10.6
    //// private - 10.7
    //// view / pure - 10.8
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
