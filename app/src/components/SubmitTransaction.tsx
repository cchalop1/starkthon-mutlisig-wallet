import { useStarknet, useStarknetInvoke } from "@starknet-react/core";
import React, { useState } from "react";
import { Contract, ContractInterface } from "starknet";
import { toBN } from "starknet/dist/utils/number";
import { bnToUint256 } from "starknet/dist/utils/uint256";

type Props = {
  contract: Contract;
};

export function SubmitTransaction(props: Props) {
  const { account } = useStarknet();
  const { invoke, error } = useStarknetInvoke({
    contract: props.contract,
    method: "submit_transaction",
  });
  const [data, setData] = useState({ receiver: "", amount: "" });

  const handleSend = async () => {
    //const res = await invoke({ args: [data.receiver, data.amount] });
    console.log(bnToUint256(toBN(data.amount)));
    const res = await invoke({
      args: [data.receiver, bnToUint256(toBN(data.amount))],
    });
    console.log(res);
    // console.log(props.mutlisig);
  };
  console.log(error);

  if (!account) {
    return null;
  }

  return (
    <div>
      <input
        type={"text"}
        id=""
        placeholder="Reciver"
        value={data.receiver}
        onChange={(e) => setData({ ...data, receiver: e.target.value })}
      />
      <input
        type={"text"}
        id=""
        placeholder="Amount"
        value={data.amount}
        onChange={(e) => setData({ ...data, amount: e.target.value })}
      />
      <button onClick={handleSend}>Submit Transaction</button>
    </div>
  );
}
