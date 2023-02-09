// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./dev/functions/FunctionsClient.sol";
// import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol"; // Once published
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Functions Copns contract
 * @notice This contract is a demonstration of using Functions.
 * @notice NOT FOR PRODUCTION USE
 */
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
  using Functions for Functions.Request;

  bytes32 public latestRequestId;
  bytes public latestResponse;
  bytes public latestError;
  
  uint public previousEpoch = 1;
  uint public epochTime = 1;

  event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

  /**
   * @notice Executes once when a contract is created to initialize state variables
   *
   * @param oracle - The FunctionsOracle contract
   */
  constructor(address oracle) FunctionsClient(oracle) ConfirmedOwner(msg.sender) {}

  /**
   * @notice Send a simple request
   * param source JavaScript source code
   * @param secrets Encrypted secrets payload
   * param args List of arguments accessible from within the source code
   * @param subscriptionId Billing ID
   */
  function executeRequest(
    //string memory source,
    bytes calldata secrets,
    Functions.Location secretsLocation,
    //string[2] memory args,
    uint64 subscriptionId,
    uint32 gasLimit
  ) public onlyOwner returns (bytes32) {
    //require(block.timestamp > previousEpoch + epochTime, "Too soon.");
    Functions.Request memory req;
    req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, sourceCode);
    
    if (secrets.length > 0) {
      if (secretsLocation == Functions.Location.Inline) {
        req.addInlineSecrets(secrets);
      } else {
        req.addRemoteSecrets(secrets);
      }
    }
    //if (args.length > 0) 
    req.addArgs(packData());

    bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit, tx.gasprice);
    latestRequestId = assignedReqID;
    previousEpoch = block.timestamp;
    return assignedReqID;
  }

  /**
   * @notice Callback that is invoked once the DON has resolved the request or hit an error
   *
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) internal override {
    // revert('test');
    //latestResponse = response;
    latestError = err;
   
    playerStates = response;
    epoch++;
    
    emit OCRResponse(requestId, response, err);
    
  }

  function updateOracleAddress(address oracle) public onlyOwner {
    setOracle(oracle);
  }

  function addSimulatedRequestId(address oracleAddress, bytes32 requestId) public onlyOwner {
    addExternalRequest(oracleAddress, requestId);
  }



  string public sourceCode;

  function setSource(string calldata incomingString) public {
    sourceCode = incomingString;
  }


  uint256 public playerIterator = 1;
  mapping(address => uint256) public addressRegistry;
  struct PlayerAction {
    string playerClass;
    uint[2] coordinatePosition;
    int[2] impulse;
    string action;
  }
  PlayerAction[] public playerActions;
  bytes public playerStates = "a";

  uint256 public epoch = 0;
  mapping(address => uint256) public actedThisEpoch;
  
  function registerPlayer(uint class, uint coordX, uint coordY) public {
    require(epoch == 0, "Game has begun.");
    require(playerIterator < 201, "Registry full.");
    require(addressRegistry[msg.sender] == 0, "Already registered.");
    require(class >= 0 && class < 3, "Invalid class.");
    require(coordX < 10 && coordX >= 0, "Outside plane.");
    require(coordY < 10 && coordY >= 0, "Outside plane.");
    addressRegistry[msg.sender] = playerIterator;
    playerIterator++;
    initializePlayer(class, coordX, coordY);
    playerStates = bytes.concat(playerStates, "9");
  }

  function initializePlayer(uint class, uint coordX, uint coordY) internal {
    PlayerAction memory newPlayer;
    newPlayer.playerClass = Strings.toString(class);
    newPlayer.coordinatePosition = [coordX, coordY];
    newPlayer.impulse = [int(0), int(0)];
    newPlayer.action = "0";
    playerActions.push(newPlayer);
  }

  function playerAct(int impulseX, int impulseY, uint action) public {
    require(addressRegistry[msg.sender] != 0, "Not registered.");
    require(actedThisEpoch[msg.sender] != epoch, "Already acted.");
    require(impulseX == 1 || impulseX == 0 || impulseX == -1, "Invalid move.");
    require(impulseY == 1 || impulseY == 0 || impulseY == -1, "Invalid move.");
    
    require(int(playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[0]) + impulseX < 10, "Out of bounds.");
    require(int(playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[0]) + impulseX >= 0, "Out of bounds.");
    require(int(playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[1]) + impulseY < 10, "Out of bounds.");
    require(int(playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[1]) + impulseY >= 0, "Out of bounds.");

    require(action >= 0 && action < 4, "Invalid action.");

    playerActions[addressRegistry[msg.sender] - 1].impulse[0] = impulseX;
    playerActions[addressRegistry[msg.sender] - 1].impulse[1] = impulseY;
    playerActions[addressRegistry[msg.sender] - 1].action = Strings.toString(action);
    
    playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[0] = uint(int(playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[0]) + impulseX);
    playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[1] = uint(int(playerActions[addressRegistry[msg.sender] - 1].coordinatePosition[1]) + impulseY);

    actedThisEpoch[msg.sender] = epoch;
  
  }


  function packData() internal view returns (string[2] memory) {
    string memory packedString = "a";
    string[2] memory packedData = [string(playerStates), "1"];
    for (uint i = 1; i < playerIterator; i++) {
      packedString = string.concat(packedString, playerActions[i - 1].playerClass, Strings.toString(playerActions[i - 1].coordinatePosition[0]), Strings.toString(playerActions[i - 1].coordinatePosition[1]), playerActions[i - 1].action);
    }
    packedData[1] = packedString;
    return packedData;
  }


}
