import { useStarknet } from "@starknet-react/core";
import React, { useState } from "react";
import { Abi, Contract, ContractFactory, Provider } from "starknet";
import mutlisig from "../abi/multisig.json";
import entryPoint from "../entry_points/multisig.json";
import program from "../programs/mutlisig.json";

export function CreateMutliSignWallet() {
  const { library } = useStarknet();
  const [contract, setContract] = useState<Contract | null>(null);

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
    const res = await contract.deploy([
      "2",
      "1163253505549043773084636590523817433456266960723228492349055772409706643766",
      "3",
      "772061925651159923841045488440688300762499409068720023139163436599814255551",
      "62626345299733262656037751443490687801442192824022130141330209312036924539",
      "2983629599073169850772701661597233831996286918810542361520918188192562321008",
    ]);
    console.log(res);
    setContract(res);
  };

  return (
    <div>
      <h4>Create Mutli sign Wallet</h4>
      {contract ? (
        contract.address
      ) : (
        <button onClick={handleCreateWallet}>Create</button>
      )}
    </div>
  );
}
