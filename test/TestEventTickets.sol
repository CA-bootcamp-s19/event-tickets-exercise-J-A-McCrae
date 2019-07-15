pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTickets.sol";
import "./EventTicketsProxy.sol";

contract TestEventTickets {

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    uint public initialBalance = 1 ether; // Initialize initialBalance

    EventTickets public contractToTest; // Declare contractToTest data type, of type EventTickets contract
    EventTicketsProxy public proxyClient; // Declare proxyClient data type, of type EventTicketsProxy contract

    string eventDesc = "Launch Party"; // Declare eventDescription
    string eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
    uint eventTotalTickets = 100; // Declare eventTotalTickets

    struct eventState { // Declare data type eventState, of type struct, to store event data
        string stateDesc;
        string stateWeb;
        uint stateTotTickets;
        uint stateSales;
        bool stateIsOpen;
    }

    eventState eventData; // eventData equals new instance of eventState

    function() external payable {} // Allow contract to receive ether

    function beforeEach() public // Declare beforeEach function
    {
        contractToTest = new EventTickets(eventDesc, eventWeb, eventTotalTickets); // contractToTest equals new instance of EventTickets
        proxyClient = new EventTicketsProxy(contractToTest); // proxyClient = new instance of EventTicketsProxy, target contractToTest

        address(proxyClient).transfer(0.1 ether); // Give buyer enough funds to buy the tickets
    }

    function testProxyAddresses() // Test proxy contracts are configured correctly
        public
    {
        Assert.equal(address(contractToTest), address(proxyClient.getTarget()), "Target contract should be contractToTest");
    }

    function getEventState() // Call readEvent function within contractToTest, and import data into eventData
        public
        returns (bool)
    {
        string memory _description; string memory _website; uint _totalTickets; uint _sales; bool _isOpen;
        ( _description, _website, _totalTickets, _sales, _isOpen ) = contractToTest.readEvent();

        eventData.stateDesc = _description;
        eventData.stateWeb = _website;
        eventData.stateTotTickets = _totalTickets;
        eventData.stateSales = _sales;
        eventData.stateIsOpen = _isOpen;
        return true;
    }

    // buyTickets

    // test for buying tickets with insufficient funds
    function testForBuyingTicketsWithInsufficientFunds() public {
        uint ticketsToPurchase = 1; // Buyer tickets to purchase
        uint ticketsPayment = 99; // Buyer payment set to less than (ticketsToPurchase * TICKET_PRICE = 100)

        bool result = proxyClient.proxyBuyTickets(ticketsToPurchase, ticketsPayment); // Buyer tries to buy tickets
        Assert.isFalse(result, "Buyer bought tickets with insufficient funds");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // test for buying more tickets than are available
    function testForBuyingMoreTicketsThanAreAvailable() public {
        uint ticketsToPurchase = 101; // Buyer tickets to purchase
        uint ticketsPayment = 10101; // Buyer payment set to more than (ticketsToPurchase * TICKET_PRICE = 10,100)

        bool result = proxyClient.proxyBuyTickets(ticketsToPurchase, ticketsPayment); // Buyer tries to buy tickets
        Assert.isFalse(result, "Buyer bought more tickets than were available");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // getRefund

    // test for refund for tickets that were not bought
    function testForRefundForTicketsThatWereNotBought() public {

        bool result = proxyClient.proxyGetRefund(); // Buyer tries to get refund before purchasing
        Assert.isFalse(result, "Buyer got refund on tickets not previously bought");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // test for refund for tickets after sale has ended
    function testForRefundForTicketsAfterSaleHasEnded() public {
        uint ticketsToPurchase = 1; // Buyer tickets to purchase
        uint ticketsPayment = 101; // Buyer payment set to more than (ticketsToPurchase * TICKET_PRICE = 100)

        bool resultOne = proxyClient.proxyBuyTickets(ticketsToPurchase, ticketsPayment); // Buyer tries to buy tickets
        Assert.isTrue(resultOne, "Buyer could not buy tickets with sufficient funds");

        bool resultTwo = contractToTest.endSale(); // Contract owner tries to end sale
        Assert.isFalse(resultTwo, "Contract owner could not end sale");

        bool resultThree = proxyClient.proxyGetRefund(); // Buyer tries to get refund
        Assert.isFalse(resultThree, "Buyer got refund on tickets after the sale ended");

        uint expSales = 1; bool expIsOpen = false;

        Assert.equal(getEventState(), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be one"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be closed"); // Verifies event state, isOpen
    }

    // endSale

    // test for ending sale from not owners address
    function testForEndingSaleFromNotOwnersAddress() public {
  
        bool result = proxyClient.proxyEndSale(); // Not contract owner tries to end sale
        Assert.isFalse(result, "Not the contract owner ended the sale");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // test for ending sale from owners address
    function testForEndingSaleFromOwnersAddress() public {

        bool result = contractToTest.endSale(); // Contract owner tries to end sale
        Assert.isFalse(result, "Contract owner could not end sale");

        uint expSales = 0; bool expIsOpen = false;

        Assert.equal(getEventState(), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be closed"); // Verifies event state, isOpen
    }
}