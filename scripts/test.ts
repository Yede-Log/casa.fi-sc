import { ethers } from "hardhat";
import { getChain } from "../services/chain";
import * as dotenv from "dotenv";

dotenv.config();

const getContractAddress = async (chainId: number, contractName: string) => {
    let chain = await getChain(chainId);
    let contractAddressIndex = chain.contracts.findIndex((contract) => contract.name === contractName);
    if (contractAddressIndex >= 0) {
        return chain.contracts[contractAddressIndex].address;
    }
    return "";
}

async function main() { 
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const loanRegistryAddress = (await getContractAddress(Number(chainId), "LoanRegistry"));
    const loanRegistry = await ethers.getContractAt("LoanRegistry", loanRegistryAddress); 
    const renTokenAddress = (await getContractAddress(Number(chainId), "RenToken"));
    const renToken = await ethers.getContractAt("RENToken", renTokenAddress); 
    const nftAddress = (await getContractAddress(Number(chainId), "RealEstateNft"));
    const nft = await ethers.getContractAt("RealEstateNft", nftAddress); 

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
