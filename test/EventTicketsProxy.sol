pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTickets.sol";

// @title Proxy test contract based on https://www.trufflesuite.com/tutorials/testing-for-throws-in-solidity-tests

contract EventTicketsProxy {

    EventTickets public eventTickets; // Declare eventTickets data type, of type EventTickets contract

    constructor(EventTickets _contractToTest) public { // Accept parameter _contractToTest, of type EventTickets contract
         eventTickets = _contractToTest; // eventTickets equals new instance of _contractToTest
    }

    function() external payable {} // Allow contract to receive ether

    function getTarget()
        public view
        returns (EventTickets) // Return data, of type EventTickets contract
    {
        return eventTickets; // Return eventTickets
    }

    // Buy tickets
    function proxyBuyTickets(uint _numT, uint256 _totPay)
        public
        returns (bool)
    {
        // Call contract eventTickets, function buyTickets, sending ticketsPayment. Return true/false if call succeeded.
        (bool noErrors, ) = address(eventTickets).call.value(_totPay)(abi.encodeWithSignature("buyTickets(uint256)", _numT));
        return noErrors;
    }

    // Get refund
    function proxyGetRefund()
        public
        returns (bool)
    {
        // Call contract eventTickets, function getRefund. Return true/false if call succeeded.
        (bool noErrors, ) = address(eventTickets).call(abi.encodeWithSignature("getRefund(uint256)"));
        return noErrors;
    }

    // End sale
    function proxyEndSale()
        public
        returns (bool)
    {
        // Call contract eventTickets, function endSale. Return true/false if call succeeded.
        (bool noErrors, ) = address(eventTickets).call(abi.encodeWithSignature("endSale(uint256)"));
        return noErrors;
    }
}




