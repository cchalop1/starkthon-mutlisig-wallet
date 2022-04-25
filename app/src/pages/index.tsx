import { useStarknetCall } from "@starknet-react/core";
import type { NextPage } from "next";
import { useMemo } from "react";
import { toBN } from "starknet/dist/utils/number";
import { ConnectWallet } from "~/components/ConnectWallet";
import { CreateMutliSignWallet } from "~/components/CreateMutliSignWallet";
import { useCounterContract } from "~/hooks/counter";

const Home: NextPage = () => {
  const { contract: counter } = useCounterContract();

  const { data: counterResult } = useStarknetCall({
    contract: counter,
    method: "counter",
    args: [],
  });

  return (
    <div>
      <h2>Wallet</h2>
      <ConnectWallet />
      <CreateMutliSignWallet />
    </div>
  );
};

export default Home;
