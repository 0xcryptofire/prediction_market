// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import {PriceConsumerV3} from "./PriceFeedOracle.sol";

contract PredictionMarket {
  enum Side { APC, PDP }
  struct Result {
    Side winner;
    Side loser;
  }
  Result public result;
  bool public electionFinished;
  PriceConsumerV3 public priceConsumer;


  mapping(Side => uint) public bets;
  mapping(address => mapping(Side => uint)) public betsPerGambler;
  address public oracle;

  constructor(address _oracle, PriceConsumerV3 _priceConsumer) {
    oracle = _oracle; 
    priceConsumer = _priceConsumer;
  }

  function getConversionRate(uint256 ethAmount) public view returns (uint256){
      // get latest price of ETH in USD
        uint256 ethPrice = uint256(priceConsumer.getLatestPrice());
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
  }

  function placeBet(Side _side) external payable {
    require(electionFinished == false, 'election is finished');
    // 18 digit number to be compared with donated amount 
    uint256 minimumUSD = 20 * 10 ** 18;
    //is the donated amount less than 50USD?
    require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
    bets[_side] += msg.value;
    betsPerGambler[msg.sender][_side] += msg.value;
  }

  function withdrawGain() external {
    uint gamblerBet = betsPerGambler[msg.sender][result.winner];
    require(gamblerBet > 0, 'you do not have any winning bet');  
    require(electionFinished == true, 'election not finished yet');
    uint gain = gamblerBet + bets[result.loser] * gamblerBet / bets[result.winner];
    betsPerGambler[msg.sender][Side.APC] = 0;
    betsPerGambler[msg.sender][Side.PDP] = 0;
    payable(msg.sender).transfer(gain);
  }

  function reportResult(Side _winner, Side _loser) external {
    require(oracle == msg.sender, "only oracle");
    result.winner = _winner;
    result.loser = _loser;
    electionFinished = true;
  }
}