import { useStarknet } from "@starknet-react/core";
import React from "react";
import { Abi, ContractFactory, Provider } from "starknet";
import { useCounterContract } from "~/hooks/counter";
import mutlisig from "../abi/multisig.json";
import entryPoint from "../entry_points/multisig.json";
import program from "../programs/mutlisig.json";

export function CreateMutliSignWallet() {
  const { library } = useStarknet();
  
  const handleCreateWallet = async () => {
    const contract = new ContractFactory(
      {
        abi: mutlisig as Abi,
        entry_points_by_type: entryPoint,
        program: program,
      },
      library as Provider
    );
    console.log(contract);
    const res = await contract.deploy();
    console.log(res);
    console.log(res.address);
  };

  return (
    <div>
      <h4>Create Mutli sign Wallet</h4>
      <button onClick={handleCreateWallet}>Create</button>
    </div>
  );
}
