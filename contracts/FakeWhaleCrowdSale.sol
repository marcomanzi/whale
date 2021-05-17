pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

import "./Crowdsale.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract FakeWhaleCrowdSale is Crowdsale {
  constructor(address _wallet, address _token) Crowdsale(21 * 10**2 * 10**6, 205 * 10 * 10**6, msg.sender, _wallet, _token, 10**9 * 10**6) {}
}
