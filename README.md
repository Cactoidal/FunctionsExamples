# Functions Examples

You can use Chainlink Functions to extend your smart contracts by running logic stored immutably on-chain.  By uploading code as a string, the **FunctionConsumer** contract's `executeRequest()` can accept that string as an argument and pass it along to the DON.

Note that you can use a separate storage contract to hold the uploaded data.  For this tutorial, we’ll just modify the **FunctionsConsumer** contract directly.  

First, [follow the ReadMe in the Chainlink functions repo](https://github.com/smartcontractkit/functions-hardhat-starter-kit/blob/main/README.md) to set up the latest version locally, and open it in your editor of choice.  Find the **FunctionsConsumer** contract.  You’ll create a new variable to hold your uploaded source code and a function for setting that code.

```
string public sourceCode;

function setString(string calldata incomingSource) public {
	sourceCode = incomingSource;
}
```

Using hardhat, upload the modified **FunctionsConsumer** contract to the chain with `npx hardhat functions-deploy-client`.  Grab the address and register it with `npx hardhat functions-sub-create`.

Then create a new javascript file and write a script for setting the string:
```
  async function main () {
	  const fs = require(“fs”)
	
	  const address = ‘Your client contract address here’;
	  const functionsConsumer = await ethers.getContractFactory(‘FunctionsConsumer’);
	  const consumerClient = await functionsConsumer.attach(address);

	  const outgoingString = fs.readFileSync(“./Name of your source code.js”).toString()

	  const tx = await consumerClient.setString(outgoingString);
    
	  console.log(tx)
    
  }

  main()
	  .then(() => process.exit(0))
	  .catch(error => {
		  console.error(error);
		  process.exit(1);
	  });
```

Use `npx hardhat run` to run your script and upload your source code on-chain.

Next, open **request.js** and create a constant pulling the code from your contract:

```
const sourceCode = await clientContract.sourceCode()
```

Then scroll down near the bottom where `executeRequest()` is called, and in the parameters replace `request.source` with `sourceCode`.  

Finally, submit your `npx hardhat functions-request`.  Instead of using your locally stored source code, the DON will now be using the code you uploaded on-chain.  

If you were to place the following into `executeRequest()`:

```
require(keccack256(bytes(source)) == keccak256(bytes(sourceCode)));
```

or within `executeRequest()` rewrite `initializeRequest()` to pass `sourceCode` instead of `source`, users can be certain that the DON will always use the uploaded on-chain logic whenever the contract executes a request.  Note that these validation methods are somewhat gas-expensive - you’ll probably need to increase the `gasLimit` value in **request.js** to at least 1,000,000.

If `setString()` is written to be owner-only, and you’ve revoked ownership, that uploaded source code is now totally immutable and the DON will always execute it as written, with whatever arguments are passed.  You could also give control of `setString()` to a multisig or DAO, in case it does one day need changes - although redeploying could be a better option in that case.

You could follow a similar process for the function arguments themselves, pulling those arguments from the chain and passing them along with the on-chain logic to the DON.  
