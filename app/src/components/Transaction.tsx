import { useStarknet, useStarknetInvoke } from "@starknet-react/core";
import React, { useState } from "react";
import { Contract, ContractInterface, number } from "starknet";

type Props = {
  contract: Contract;
  name: string;
  idx: number;
};

export function Transaction(props: Props) {
  const { account } = useStarknet();
  const { invoke, error } = useStarknetInvoke({
    contract: props.contract,
    method: props.name,
  });
  const handleSend = async () => {
    const res = await invoke({
      args: [String(props.idx)],
    });
    console.log(res);
  };
  console.log(error);

  if (!account) {
    return null;
  }

  return (
    <div>
      <button onClick={handleSend}>{props.name}</button>
    </div>
  );
}
