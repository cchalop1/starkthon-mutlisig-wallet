import { useStarknet, useStarknetInvoke } from "@starknet-react/core";
import React, { useState } from "react";

export function Transaction(props) {
  const { account } = useStarknet();
  const { invoke, error } = useStarknetInvoke({
    contract: props.contract,
    method: props.name,
  });
  const [data, setData] = useState({ tx_id: "" });

  const handleSend = async () => {
    const res = await invoke({
      args: [data.tx_id],
    });
    console.log(res);
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
        placeholder="tx id"
        value={data.tx_id}
        onChange={(e) => setData({ ...data, tx_id: e.target.value })}
      />
      <button onClick={handleSend}>{props.name}</button>
    </div>
  );
}
