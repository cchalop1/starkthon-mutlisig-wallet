import { useContract, useStarknetCall } from "@starknet-react/core";
import type { NextPage } from "next";
import { ConnectWallet } from "~/components/ConnectWallet";
import { CreateMutliSignWallet } from "~/components/l1tol2/CreateMutliSignWallet";
import { SubmitTransaction } from "../components/l1tol2/SubmitTransaction";
import { Transaction } from "../components/l1tol2/Transaction";

import MultisigAbi from "../abi/multisig_tx.json";
import { Abi } from "starknet";
import { useMemo } from "react";
import { toBN } from "starknet/dist/utils/number";

const Home: NextPage = () => {
  const { contract: mutlisig } = useContract({
    abi: MultisigAbi as Abi,
    address:
      "0x023d3a5d02e079b9df97539f23479d6be9e1432deeaef942a37edfa4f1d8ead7",
  });

  const { data: numberTransaction } = useStarknetCall({
    contract: mutlisig,
    method: "view_tx_count",
    args: [],
  });

  const transactionsCounts = useMemo(() => {
    if (numberTransaction && numberTransaction.length > 0) {
      const value = toBN(numberTransaction[0]);
      return Number(value.toString(10));
    }
  }, [numberTransaction]);

  return (
    <div>
      <h2>Wallet</h2>
      <ConnectWallet />
      <CreateMutliSignWallet />
      {mutlisig && (
        <>
          <SubmitTransaction contract={mutlisig} />
          {(new Array(transactionsCounts)).fill(null).map((_, idx) => (
            <div style={{display: "flex", alignItems: "center"}}>
              <h3>{idx}</h3>
              <Transaction
                idx={idx}
                contract={mutlisig}
                name="confirm_transaction"
              />
              <Transaction
                idx={idx}
                contract={mutlisig}
                name="revoke_confirmation"
              />
              <Transaction
                idx={idx}
                contract={mutlisig}
                name="execute_transaction"
              />
            </div>
          ))}
        </>
      )}
    </div>
  );
};

export default Home;
