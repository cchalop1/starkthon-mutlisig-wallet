import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import MultisigAbi from '../abi/multisig.json'

export function useMutliContract(props) {
  return useContract({
    abi: MultisigAbi as Abi,
    address: '0x013577c5a03db29e89795021a1b90ac38c533b9ae7cb9b272392ffe8e4cd01ee',
  })
}
