import { useContract, useStarknetCall } from "@starknet-react/core";
import type { NextPage } from "next";
import { ConnectWallet } from "~/components/ConnectWallet";
import { CreateMutliSignWallet } from "~/components/CreateMutliSignWallet";
import { SubmitTransaction } from "../components/SubmitTransaction";
import { Transaction } from "../components/Transaction";

import MultisigAbi from "../abi/multisig.json";
import { Abi } from "starknet";
import { useMemo } from "react";
import { toBN } from "starknet/dist/utils/number";

const Home: NextPage = () => {
  const { contract: mutlisig } = useContract({
    abi: MultisigAbi as Abi,
    address:
      "0x03510914c3303fefce9ade621791695f0055c04a82e28d8b969dad36e3a1e0c8",
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
