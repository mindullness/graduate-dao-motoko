export const idlFactory = ({ IDL }) => {
  const ProposalContent__1 = IDL.Variant({
    'AddGoal' : IDL.Text,
    'AddMentor' : IDL.Principal,
    'ChangeManifesto' : IDL.Text,
  });
  const ProposalId = IDL.Nat;
  const Result_3 = IDL.Variant({ 'ok' : ProposalId, 'err' : IDL.Text });
  const ProposalId__1 = IDL.Nat;
  const ProposalStatus = IDL.Variant({
    'Open' : IDL.Null,
    'Rejected' : IDL.Null,
    'Accepted' : IDL.Null,
  });
  const Time = IDL.Int;
  const ProposalContent = IDL.Variant({
    'AddGoal' : IDL.Text,
    'AddMentor' : IDL.Principal,
    'ChangeManifesto' : IDL.Text,
  });
  const Vote = IDL.Record({
    'member' : IDL.Principal,
    'votingPower' : IDL.Nat,
    'yesOrNo' : IDL.Bool,
  });
  const Proposal = IDL.Record({
    'id' : ProposalId__1,
    'status' : ProposalStatus,
    'created' : Time,
    'creator' : IDL.Principal,
    'content' : ProposalContent,
    'votes' : IDL.Vec(Vote),
    'voteScore' : IDL.Int,
    'executed' : IDL.Opt(Time),
  });
  const Role = IDL.Variant({
    'Graduate' : IDL.Null,
    'Mentor' : IDL.Null,
    'Student' : IDL.Null,
  });
  const Member = IDL.Record({ 'name' : IDL.Text, 'role' : Role });
  const Result_2 = IDL.Variant({ 'ok' : Member, 'err' : IDL.Text });
  const Result_1 = IDL.Variant({ 'ok' : Proposal, 'err' : IDL.Text });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  return IDL.Service({
    'createProposal' : IDL.Func([ProposalContent__1], [Result_3], []),
    'getAllProposal' : IDL.Func([], [IDL.Vec(Proposal)], ['query']),
    'getGoals' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getIdWebpage' : IDL.Func([], [IDL.Principal], ['query']),
    'getManifesto' : IDL.Func([], [IDL.Text], ['query']),
    'getMember' : IDL.Func([IDL.Principal], [Result_2], ['query']),
    'getName' : IDL.Func([], [IDL.Text], ['query']),
    'getProposal' : IDL.Func([ProposalId], [Result_1], ['query']),
    'graduate' : IDL.Func([IDL.Principal], [Result], []),
    'registerMember' : IDL.Func([IDL.Text], [Result], []),
    'voteProposal' : IDL.Func([ProposalId, IDL.Bool], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
