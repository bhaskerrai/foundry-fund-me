// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe fundMe;

    address USER = makeAddr("user"); //making a user that will make the transactions with built-in function makeAddr("string")

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {  
        // console.log("Chalo, ab dekho main kya karta hoon.");
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //vm.deal sets balance of an address. In this case we are giving some money to our address in order to make TX.
    }

    function testMinimumDollarIs5() public {
        assert(fundMe.MINIMUM_USD() == 5e18);
    }

    function testOwner() public {
        assert(fundMe.getOwner() == msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();

        assert(version == 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //this means, that the next line should fail!

        fundMe.fund();  //sending 0 value 
        // fundMe.fund{value: 1}();
    }


    function testFundUpdatedFundedDataStructure() public {

        vm.prank(USER); //the next TX will be sent by USER (vm.prank sets msg.sender to the specified address for the next call. )

        fundMe.fund{ value: SEND_VALUE }();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        assert(amountFunded == SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER); //the next TX will be sent by USER (vm.prank sets msg.sender to the specified address for the next call. )

        fundMe.fund{ value: SEND_VALUE }();

        address funder = fundMe.getFunder(0);

        assert(funder == USER);
    }

    modifier funded() {
        vm.prank(USER); //the next TX will be sent by USER 
        fundMe.fund{ value: SEND_VALUE }();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();

    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();


        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assert(endingOwnerBalance == startingOwnerBalance + startingFundMeBalance);
        assert(endingFundMeBalance == 0);
    }




    function testWithdrawWithMultipleFunder() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);  //hoax vm.prank aur vm.deal duno ke kaam ek sath kardeta hai.
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assert(endingOwnerBalance == startingOwnerBalance + startingFundMeBalance);
        assert(endingFundMeBalance == 0);
    }

    function testCheapWithdrawWithMultipleFunder() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);  //hoax vm.prank aur vm.deal duno ke kaam ek sath kardeta hai.
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assert(endingOwnerBalance == startingOwnerBalance + startingFundMeBalance);
        assert(endingFundMeBalance == 0);
    }

}   
