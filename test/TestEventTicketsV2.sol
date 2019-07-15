pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTicketsV2.sol";
import "./EventTicketsV2Proxy.sol";

contract TestEventTicketsV2 {

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    uint public initialBalance = 1 ether; // Initialize initialBalance

    EventTicketsV2 public contractToTestV2; // Declare contractToTest data type, of type EventTickets contract
    EventTicketsV2Proxy public proxyClient; // Declare proxyClient data type, of type EventTicketsProxy contract

/*  string eventDesc = "Launch Party"; // Declare eventDescription                 *Events are added by proxyClient in V2* */
/*  string eventWeb = "https://www.besticoever.net"; // Declare eventWebsite       *Events are added by proxyClient in V2* */
/*  uint eventTotalTickets = 100; // Declare eventTotalTickets                     *Events are added by proxyClient in V2* */

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
        contractToTestV2 = new EventTicketsV2(); // contractToTestV2 equals new instance of EventTicketsV2
        proxyClient = new EventTicketsV2Proxy(contractToTestV2); // proxyClient = new instance of EventTicketsV2Proxy, target contractToTestV2

        address(proxyClient).transfer(0.1 ether); // Give buyer enough funds to buy the tickets
    }

    function testProxyAddresses() // Test proxy contracts are configured correctly
        public
    {
        Assert.equal(address(contractToTestV2), address(proxyClient.getTarget()), "Target contract should be contractToTest");
    }

    function getEventState(uint _eventID) // Call readEvent function within contractToTest, and import data into eventData
        public
        returns (bool)
    {
        string memory _description; string memory _website; uint _totalTickets; uint _sales; bool _isOpen;
        ( _description, _website, _totalTickets, _sales, _isOpen ) = contractToTestV2.readEvent(_eventID);

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
        string memory eventDesc = "Launch Party"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add event
        Assert.equal(resultOne, 0, "Owner could not add a new event");

        uint eventID = 0; // Client eventID for tickets purchase
        uint ticketsToPurchase = 1; // Client tickets to purchase
        uint ticketsPayment = 99; // Client payment set to less than (ticketsToPurchase * TICKET_PRICE = 100)

        bool resultTwo = proxyClient.proxyBuyTickets(eventID, ticketsToPurchase, ticketsPayment); // Client tries to buy tickets
        Assert.isFalse(resultTwo, "Buyer bought tickets with insufficient funds");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // test for buying more tickets than are available
    function testForBuyingMoreTicketsThanAreAvailable() public {
        string memory eventDesc = "Launch Party"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add event
        Assert.equal(resultOne, 0, "Owner could not add a new event");
 
        uint eventID = 0; // Client eventID for tickets purchase
        uint ticketsToPurchase = 101; // Client tickets to purchase
        uint ticketsPayment = 10101; // Client payment set to more than (ticketsToPurchase * TICKET_PRICE = 10,100)

        bool resultTwo = proxyClient.proxyBuyTickets(eventID, ticketsToPurchase, ticketsPayment); // Client tries to buy tickets
        Assert.isFalse(resultTwo, "Buyer bought more tickets than were available");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // getRefund

    // test for refund for tickets that were not bought
    function testForRefundForTicketsThatWereNotBought() public {
        string memory eventDesc = "Launch Party"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add event
        Assert.equal(resultOne, 0, "Owner could not add a new event");

        uint eventID = 0; // Client eventID for tickets refund

        bool resultTwo = proxyClient.proxyGetRefund(eventID); // Client tries to get refund before purchasing
        Assert.isFalse(resultTwo, "Buyer got refund on tickets not previously bought");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // test for refund for tickets after sale has ended
    function testForRefundForTicketsAfterSaleHasEnded() public {
        string memory eventDesc = "Launch Party"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add event
        Assert.equal(resultOne, 0, "Owner could not add a new event");

        uint eventID = 0; // Client eventID for tickets purchase
        uint ticketsToPurchase = 1; // Client tickets to purchase
        uint ticketsPayment = 101; // Client payment set to more than (ticketsToPurchase * TICKET_PRICE = 100)

        bool resultTwo = proxyClient.proxyBuyTickets(eventID, ticketsToPurchase, ticketsPayment); // Client tries to buy tickets
        Assert.isTrue(resultTwo, "Buyer could not buy tickets with sufficient funds");

        bool resultThree = contractToTestV2.endSale(eventID); // Contract owner tries to end sale
        Assert.isFalse(resultThree, "Contract owner could not end sale");

        bool resultFour = proxyClient.proxyGetRefund(eventID); // Client tries to get refund
        Assert.isFalse(resultFour, "Buyer got refund on tickets after the sale ended");

        uint expSales = 1; bool expIsOpen = false;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be one"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be closed"); // Verifies event state, isOpen
    }

    // endSale

    // test for ending sale from not owners address
    function testForEndingSaleFromNotOwnersAddress() public {
        string memory eventDesc = "Launch Party"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add event
        Assert.equal(resultOne, 0, "Owner could not add a new event");

        uint eventID = 0; // Client eventID

        bool resultTwo = proxyClient.proxyEndSale(eventID); // Not contract owner tries to end sale
        Assert.isFalse(resultTwo, "Not the contract owner ended the sale");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

    // test for ending sale from owners address
    function testForEndingSaleFromOwnersAddress() public {
        string memory eventDesc = "Launch Party"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add event
        Assert.equal(resultOne, 0, "Owner could not add a new event");

        uint eventID = 0; // Client eventID

        bool resultTwo = contractToTestV2.endSale(eventID); // Contract owner tries to end sale
        Assert.isFalse(resultTwo, "Contract owner could not end sale");

        uint expSales = 0; bool expIsOpen = false;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be closed"); // Verifies event state, isOpen
    }

    // addEvents

    // test for adding multiple events
    function testForAddingMultipleEvents() public {
        string memory eventDesc = "Launch Party 1"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add first event
        Assert.equal(resultOne, 0, "Owner could not add a new event");

        string memory _eventDesc = "Launch Party 2"; // Declare eventDescription
        string memory _eventWeb = "https://www.evenbetterico.net"; // Declare eventWebsite
        uint _eventTotalTickets = 1000; // Declare eventTotalTickets

        uint resultTwo = contractToTestV2.addEvent(_eventDesc, _eventWeb, _eventTotalTickets); // Owner tries to add second event
        Assert.equal(resultTwo, 1, "Owner could not add a new event");

        uint eventID = 0; // Client eventID for tickets purchase
        uint ticketsToPurchase = 99; // Client tickets to purchase
        uint ticketsPayment = 9901; // Client payment set to more than (ticketsToPurchase * TICKET_PRICE = 9,990)

        bool resultThree = proxyClient.proxyBuyTickets(eventID, ticketsToPurchase, ticketsPayment); // Client tries to buy tickets
        Assert.isTrue(resultThree, "Buyer could not buy tickets with sufficient funds");

        uint _eventID = 1; // Client eventID for tickets purchase
        uint _ticketsToPurchase = 999; // Client tickets to purchase
        uint _ticketsPayment = 99901; // Client payment set to more than (ticketsToPurchase * TICKET_PRICE = 99,990)

        bool resultFour = proxyClient.proxyBuyTickets(_eventID, _ticketsToPurchase, _ticketsPayment); // Client tries to buy tickets
        Assert.isTrue(resultFour, "Buyer could not buy tickets with sufficient funds");

        uint expSales = 99; bool expIsOpen = true;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be 99"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen

        uint _expSales = 999; bool _expIsOpen = true;

        Assert.equal(getEventState(_eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, _expSales, "Ticket sales should be 999"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, _expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }

/*
    // test for ending multiple sales
    function testForEndingMultipleSales() public {
        string memory eventDesc = "Launch Party 1"; // Declare eventDescription
        string memory eventWeb = "https://www.besticoever.net"; // Declare eventWebsite
        uint eventTotalTickets = 100; // Declare eventTotalTickets

        uint resultOne = contractToTestV2.addEvent(eventDesc, eventWeb, eventTotalTickets); // Owner tries to add first event
        Assert.equal(resultOne, 0, "Owner could not add a new event");

        string memory _eventDesc = "Launch Party 2"; // Declare eventDescription
        string memory _eventWeb = "https://www.evenbetterico.net"; // Declare eventWebsite
        uint _eventTotalTickets = 1000; // Declare eventTotalTickets

        uint resultTwo = contractToTestV2.addEvent(_eventDesc, _eventWeb, _eventTotalTickets); // Owner tries to add second event
        Assert.equal(resultTwo, 1, "Owner could not add a new event");

        uint eventID = 0; // Client eventID for tickets purchase

        bool resultThree = proxyClient.proxyEndSale(eventID); // Not contract owner tries to end sale
        Assert.isFalse(resultThree, "Not the contract owner ended the sale");

        uint _eventID = 1; // Client eventID for tickets purchase

        bool resultFour = proxyClient.proxyEndSale(_eventID); // Not contract owner tries to end sale
        Assert.isFalse(resultFour, "Not the contract owner ended the sale");

        uint expSales = 0; bool expIsOpen = true;

        Assert.equal(getEventState(eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, expIsOpen, "Event should be open"); // Verifies event state, isOpen

        uint _expSales = 0; bool _expIsOpen = true;

        Assert.equal(getEventState(_eventID), true, "Could not get retrieve event state"); // Verifies execution of getEventState
        Assert.equal(eventData.stateSales, _expSales, "Ticket sales should be zero"); // Verifies event state, sales
        Assert.equal(eventData.stateIsOpen, _expIsOpen, "Event should be open"); // Verifies event state, isOpen
    }
*/


}