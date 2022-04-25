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
    l2_contract: "",
    function_selector: "",
    payload: "",
  });

  const handleSend = async () => {
    const args = [data.l2_contract, data.function_selector, data.payload.split(",")];
    const res = await invoke({
      args: args,
    }).catch((e) => {
      console.log("titi", e);
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
        placeholder="L2 contract"
        value={data.l2_contract}
        onChange={(e) => setData({ ...data, l2_contract: e.target.value })}
      />

      <input
        type={"text"}
        id=""
        placeholder="function selector"
        value={data.function_selector}
        onChange={(e) =>
          setData({ ...data, function_selector: e.target.value })
        }
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
