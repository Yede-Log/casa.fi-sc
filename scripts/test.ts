import { ethers } from "hardhat";
import { getChain } from "../services/chain";
import * as dotenv from "dotenv";
import { Contract, Wallet } from "ethers";
import { AutomationRegistrarInterface, LinkTokenInterface, LoanRegistry, RENToken, RealEstateNft } from "../typechain-types";
import { connectDB } from "../config/database";

dotenv.config();

const getContractAddress = async (chainId: number, contractName: string) => {
    let chain = await getChain(chainId);
    let contractAddressIndex = chain.contracts.findIndex((contract) => contract.name === contractName);
    if (contractAddressIndex >= 0) {
        return chain.contracts[contractAddressIndex].address;
    }
    return "";
}

const createLoanAccount = async (lender: Wallet, borrower: Wallet, assetOwner: Wallet, 
    loanRegistry: LoanRegistry, nftAddress: string, renTokenAddress: string) => {
    let tx = await loanRegistry.connect(lender).create_loan_account(borrower.address, assetOwner.address, nftAddress, 1, renTokenAddress)
    return tx.hash
}

const disburseLoan = async (loanAccountAddress: string, lender: Wallet, borrower: Wallet, assetOwner: Wallet, 
    loanRegistry: LoanRegistry, token: RENToken, nft: RealEstateNft, 
    automationRegistrar: string, linkToken: LinkTokenInterface
) => {
    await token.connect(lender).approve(loanAccountAddress, 500000000000);
    await token.connect(borrower).approve(loanAccountAddress, 500000000000);
    await nft.connect(assetOwner).approve(loanAccountAddress, 1);

    await loanRegistry.connect(lender).setAutomationRegistrar(automationRegistrar);
    await loanRegistry.connect(lender).setLinkAddress((await linkToken.getAddress()));

    await linkToken.connect(lender).transfer((await loanRegistry.getAddress()), 2_000_000_000_000_000_000n);

    let tx = await loanRegistry.connect(lender).disburse_loan(loanAccountAddress, 500000000000, 600, 60, 850);
    return tx;
}

async function main() { 
    await connectDB();
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const loanRegistryAddress = (await getContractAddress(Number(chainId), "LoanRegistry"));
    const loanRegistry = await ethers.getContractAt("LoanRegistry", loanRegistryAddress); 
    const renTokenAddress = (await getContractAddress(Number(chainId), "RENToken"));
    const renToken = await ethers.getContractAt("RENToken", renTokenAddress); 
    const nftAddress = (await getContractAddress(Number(chainId), "RealEstateNft"));
    const nft = await ethers.getContractAt("RealEstateNft", nftAddress); 
    
    const borrower = new ethers.Wallet(process.env.BORROWER_PRIVATE_KEY ?? "").connect(ethers.provider);
    const lender = new ethers.Wallet(process.env.LENDER_PRIVATE_KEY ?? "").connect(ethers.provider);
    const assetOwner = new ethers.Wallet(process.env.ASSET_OWNER_PRIVATE_KEY ?? "").connect(ethers.provider);

    const automationRegistrar = await ethers.getContractAt(
        "AutomationRegistrarInterface", process.env.AUTOMATION_REGISTRAR ?? ""
    );

    const linkToken = await ethers.getContractAt(
        "LinkTokenInterface", process.env.LINK_TOKEN_ADDRESS ?? ""
    );

    // let hash = await createLoanAccount(lender, borrower, assetOwner, loanRegistry, nftAddress, renTokenAddress);
    // console.log(`Loan Account Created at: ${hash}`);

    let tx = await disburseLoan(
        "0x6389f475216035Eb1401Dc643bF94F4f68a0134E", lender, borrower, assetOwner, loanRegistry,
        renToken, nft, (await automationRegistrar.getAddress()), linkToken
    )
    console.log(tx.hash);
    return;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
