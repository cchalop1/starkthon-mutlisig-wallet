import { useStarknet, useStarknetInvoke } from "@starknet-react/core";
import React, { useState } from "react";
import { Contract } from "starknet";

type Props = {
  contract: Contract;
};

export function SubmitTransaction(props: Props) {
  const { account } = useStarknet();
  const { invoke, error } = useStarknetInvoke({
    contract: props.contract,
    method: "submit_transaction",
  });
  console.log(error);
  const [data, setData] = useState({
    l1_contract: "",
    payload: "",
  });

  const handleSend = async () => {
    const args = [data.l1_contract, data.payload.split(",").length, data.payload.split(",")];
    console.log(args);
    const res = await invoke({
      args: args,
    });
    console.log(res);
  };

  if (!account) {
    return null;
  }

  return (
    <div>
      <input
        type={"text"}
        id=""
        placeholder="L1 contract"
        value={data.l1_contract}
        onChange={(e) => setData({ ...data, l1_contract: e.target.value })}
      />
      <input
        type={"text"}
        id=""
        placeholder="Payload"
        value={data.payload}
        onChange={(e) => setData({ ...data, payload: e.target.value })}
      />
      <button onClick={handleSend}>Submit Transaction</button>
    </div>
  );
}
