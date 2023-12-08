import { ethers } from "ethers";
import mongoose from "../config/database";

export interface Chain {
    _id: mongoose.Types.ObjectId,
    chainId: number,
    name: string,
    rpc: string,
    contracts: Contract[],
    syncedBlock: number | null,
    createdAt: Date,
    updateAt: Date
}

export interface Contract {
    name: string
    address: string,
    abi: ethers.ContractInterface
}