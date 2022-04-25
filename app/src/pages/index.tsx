import { useStarknetCall, useStarknetInvoke } from "@starknet-react/core";
import type { NextPage } from "next";
import { toBN } from "starknet/dist/utils/number";
import { ConnectWallet } from "~/components/ConnectWallet";
import { CreateMutliSignWallet } from "~/components/CreateMutliSignWallet";
import { useCounterContract } from "~/hooks/counter";
import { IncrementCounter } from "../components/IncrementCounter";
import { SubmitTransaction } from "../components/SubmitTransaction";
import { Transaction } from "../components/Transaction";
import { useMutliContract } from "../hooks/multisig";

const Home: NextPage = () => {
  const { contract: mutlisig } = useMutliContract();
  console.log(mutlisig);

  return (
    <div>
      <h2>Wallet</h2>
      <ConnectWallet />
      <CreateMutliSignWallet />
      {mutlisig && (
        <>
          <SubmitTransaction contract={mutlisig} />
          <Transaction contract={mutlisig} name="confirm_transaction" />
          <Transaction contract={mutlisig} name="revoke_confirmation" />
          <Transaction contract={mutlisig} name="execute_transaction" />
        </>
      )}
      <IncrementCounter />
    </div>
  );
};

export default Home;
