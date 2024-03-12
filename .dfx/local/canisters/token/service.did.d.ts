import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type Result = { 'ok' : null } |
  { 'err' : string };
export interface _SERVICE {
  'balanceOf' : ActorMethod<[Principal], bigint>,
  'balanceOfArray' : ActorMethod<[Array<Principal>], Array<bigint>>,
  'burn' : ActorMethod<[Principal, bigint], Result>,
  'mint' : ActorMethod<[Principal, bigint], Result>,
  'tokenName' : ActorMethod<[], string>,
  'tokenSymbol' : ActorMethod<[], string>,
  'totalSupply' : ActorMethod<[], bigint>,
  'transfer' : ActorMethod<[Principal, Principal, bigint], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: ({ IDL }: { IDL: IDL }) => IDL.Type[];
