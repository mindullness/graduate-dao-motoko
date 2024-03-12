import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Member { 'name' : string, 'role' : Role }
export interface Proposal {
  'id' : ProposalId__1,
  'status' : ProposalStatus,
  'created' : Time,
  'creator' : Principal,
  'content' : ProposalContent,
  'votes' : Array<Vote>,
  'voteScore' : bigint,
  'executed' : [] | [Time],
}
export type ProposalContent = { 'AddGoal' : string } |
  { 'AddMentor' : Principal } |
  { 'ChangeManifesto' : string };
export type ProposalContent__1 = { 'AddGoal' : string } |
  { 'AddMentor' : Principal } |
  { 'ChangeManifesto' : string };
export type ProposalId = bigint;
export type ProposalId__1 = bigint;
export type ProposalStatus = { 'Open' : null } |
  { 'Rejected' : null } |
  { 'Accepted' : null };
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Result_1 = { 'ok' : Proposal } |
  { 'err' : string };
export type Result_2 = { 'ok' : Member } |
  { 'err' : string };
export type Result_3 = { 'ok' : ProposalId } |
  { 'err' : string };
export type Role = { 'Graduate' : null } |
  { 'Mentor' : null } |
  { 'Student' : null };
export type Time = bigint;
export interface Vote {
  'member' : Principal,
  'votingPower' : bigint,
  'yesOrNo' : boolean,
}
export interface _SERVICE {
  'createProposal' : ActorMethod<[ProposalContent__1], Result_3>,
  'getAllProposal' : ActorMethod<[], Array<Proposal>>,
  'getGoals' : ActorMethod<[], Array<string>>,
  'getIdWebpage' : ActorMethod<[], Principal>,
  'getManifesto' : ActorMethod<[], string>,
  'getMember' : ActorMethod<[Principal], Result_2>,
  'getName' : ActorMethod<[], string>,
  'getProposal' : ActorMethod<[ProposalId], Result_1>,
  'graduate' : ActorMethod<[Principal], Result>,
  'registerMember' : ActorMethod<[string], Result>,
  'voteProposal' : ActorMethod<[ProposalId, boolean], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: ({ IDL }: { IDL: IDL }) => IDL.Type[];
