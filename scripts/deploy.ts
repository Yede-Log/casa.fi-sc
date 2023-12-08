import { ethers } from "hardhat";

import { getChain, saveChain } from "../services/chain";
import { BaseContract } from "ethers";

async function saveContract(name: string, contract: BaseContract) {
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const chain = await getChain(Number(chainId));
    let contractIndex = chain.contracts.findIndex((chainContract) => chainContract.name === name);
    if(contractIndex < 0) {
        chain.contracts.push({
            name: "RealEstateNft",
            address: contract.target.toString(),
            abi: JSON.parse(contract.interface.formatJson())
        })
    } else {
        chain.contracts[contractIndex].address = contract.target.toString();
        chain.contracts[contractIndex].abi = JSON.parse(contract.interface.formatJson());
    }
    saveChain(chain);
    console.log(`Deployed ${name} and saved address: ${contract.target}`);
}

async function main() { 
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying from account : ${deployer.address}`);

    // const reaEstateNft = await ethers.deployContract("RealEstateNft", [], {});
    // await reaEstateNft.waitForDeployment();
    // console.log(
    //     `Real Estate Nft contract address is ${reaEstateNft.target}` // 0x7064d0e8BAa9970945BC9f207bcA1C8d2F1919cA
    // );
    // await saveContract("RealEstateNft", reaEstateNft);

    // const token = await ethers.deployContract("RENToken", [100_000_000_000_000], {});
    // await token.waitForDeployment();
    // console.log(
    //     `Deployed RENToken to address: ${token.target}` // 0xFa9772F459f8855728C096203f1e530dDeAB62e0
    // )
    // await saveContract("RENToken", token);

    const loanRegistry = await ethers.deployContract("LoanRegistry", [], {}); 
    await loanRegistry.waitForDeployment();
    console.log(
        `Deployed LoanRegistry to address: ${loanRegistry.target}` // 0xc4C85702E8565360d8836d143b0Fceee84d7F37E
    );
    await saveContract("LoanRegistry", loanRegistry);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
