pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTicketsV2.sol";

// @title Proxy test contract based on https://www.trufflesuite.com/tutorials/testing-for-throws-in-solidity-tests

contract EventTicketsV2Proxy {

    EventTicketsV2 public eventTicketsV2; // Declare eventTicketsV2 data type, of type EventTicketsV2 contract

    constructor(EventTicketsV2 _contractToTestV2) public { // Accept parameter _contractToTestV2, of type EventTicketsV2 contract
         eventTicketsV2 = _contractToTestV2; // eventTicketsV2 equals new instance of _contractToTestV2
    }

    function() external payable {} // Allow contract to receive ether

    function getTarget()
        public view
        returns (EventTicketsV2) // Return data, of type EventTicketsV2 contract
    {
        return eventTicketsV2; // Return eventTicketsV2
    }

    // Buy tickets
    function proxyBuyTickets(uint _eventID, uint _numT, uint256 _totPay)
        public
        returns (bool)
    {
        // Call contract eventTicketsV2, function buyTickets, sending _totPay. Return true/false if call succeeded.
        (bool noErrors, ) = address(eventTicketsV2).call.value(_totPay)(abi.encodeWithSignature("buyTickets(uint256,uint256)", _eventID, _numT));
        return noErrors;
    }

    // Get refund
    function proxyGetRefund(uint eventID)
        public
        returns (bool)
    {
        // Call contract eventTicketsV2, function getRefund. Return true/false if call succeeded.
        (bool noErrors, ) = address(eventTicketsV2).call(abi.encodeWithSignature("getRefund(uint256)", eventID));
        return noErrors;
    }

    // End sale
    function proxyEndSale(uint eventID)
        public
        returns (bool)
    {
        // Call contract eventTicketsV2, function endSale. Return true/false if call succeeded.
        (bool noErrors, ) = address(eventTicketsV2).call(abi.encodeWithSignature("endSale(uint256)", eventID));
        return noErrors;
    }

    // Add event
    function proxyAddEvent(string memory _description, string memory _website, uint _totalTickets)
        public
        returns (bool)
    {
        // Call contract eventTicketsV2, function addEvent. Return true/false if call succeeded.
        (bool noErrors, ) = address(eventTicketsV2).call(abi.encodeWithSignature("addEvent(uint256)", _description, _website, _totalTickets));
        return noErrors;
    }
}




