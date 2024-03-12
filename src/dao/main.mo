import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Array "mo:base/Array";
import Types "types";
import MBToken "canister:token";
import Webpage "canister:webpage";

actor Dao {

	type Result<A, B> = Result.Result<A, B>;
	type Member = Types.Member;
	type ProposalContent = Types.ProposalContent;
	type ProposalId = Types.ProposalId;
	type Proposal = Types.Proposal;
	type ProposalStatus = Types.ProposalStatus;
	type Vote = Types.Vote;
	type HttpRequest = Types.HttpRequest;
	type HttpResponse = Types.HttpResponse;
	type Role = Types.Role;

	// The principal of the Webpage canister associated with this DAO canister (needs to be updated with the ID of your Webpage canister)
	stable let canisterIdWebpage : Principal = Principal.fromActor(Webpage);
	stable var manifesto = "The biggest challenge in life is to win yourself";
	stable let name = "True Self";
	stable var goals : [Text] = ["Challenge yourself", "Break yourself", "Find yourself", "Complete yourself", "True self"];

	private stable var memberEntries : [(Principal, Member)] = [];
	private var members = HashMap.HashMap<Principal, Member>(1, Principal.equal, Principal.hash);

	// let firstMentor = Principal.fromText("nkqop-siaaa-aaaaj-qa3qq-cai");
	// if (members.get(firstMentor) == null) {
	//   members.put(firstMentor, { name = "motoko_bootcamp"; role = #Mentor });
	// };

	// 1. Returns the name of the DAO
	public query func getName() : async Text {
		return name;
	};

	// 2. Returns the manifesto of the DAO
	public query func getManifesto() : async Text {
		return manifesto;
	};

	// 3. Returns the goals of the DAO
	public query func getGoals() : async [Text] {
		return goals;
	};

	/** Requirement 1-2. Membership and Token Allocation and Role System **/
	
	// 4. Register a new member in the DAO with the given name and principal of the caller
	// Airdrop 10 MBC tokens to the new member
	// New members are always Student
	// Returns an error if the member already exists
	public shared ({ caller }) func registerMember(name : Text) : async Result<(), Text> {
		return switch (members.get(caller)) {
			case null {
				let newMember = {
					name = name;
					role = #Student;
				};
				members.put(caller, newMember);
				#ok();
			};
			case (?any) #err("Already registered!!!");
		};
	};

	// 5. Get the member with the given principal
	// Returns an error if the member does not exist
	public query func getMember(p : Principal) : async Result<Member, Text> {
		return switch (members.get(p)) {
			case null #err("The member does not exist");
			case (?member) #ok(member);
		};
	};

	// 6. Graduate the student with the given principal
	// Returns an error if the student does not exist or is not a student
	// Returns an error if the caller is not a mentor
	public shared ({ caller }) func graduate(studentId : Principal) : async Result<(), Text> {
		return switch (members.get(caller)) {
			case null #err("Mentor does not exist");
			case (?mentor) {
				if (not verifyRole(mentor, #Mentor)) return #err("Only mentor can graduate a student");

				return _updateMember(studentId, #Student, #Graduate);
			};
		};
	};

	private stable var nextId : Nat = 1;
	private func hashNat(n : Nat) : Hash.Hash {
		return Text.hash(Nat.toText(n));
	};

	private stable var proposalEntries : [(ProposalId, Proposal)] = [];
	private var mapOfProposals : HashMap.HashMap<ProposalId, Proposal> = HashMap.HashMap<ProposalId, Proposal>(1, Nat.equal, hashNat);

	private func generateProposalId() : ProposalId {
		let proposalId : ProposalId = nextId;
		nextId += 1;
		return proposalId;
	};

	/** 3. Proposal Creation - Create a new proposal and returns its id **/
	
	// 7. Create a new proposal and returns its id
	// Returns an error if the caller is not a mentor or doesn't own at least 1 MBC token
	public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
		// Debug.print(debug_show (content));
		let member = switch (members.get(caller)) {
			// Check caller is a member
			case null return #err("Not a member");
			case (?m) m;
		};
		// // Check caller is a Mentor
		if (not verifyRole(member, #Mentor)) return #err("Not authorized to create a proposal");

		// Check balance remain at least 1 MBT
		let balance = await MBToken.balanceOf(caller);
		if (balance < 1) return #err("The caller does not have enough tokens to create a proposal");

		// Creating a proposal should require to burn 1 token.
		if (Result.isErr(await MBToken.burn(caller, 1))) return #err("Cannot burn MBT to create a proposal");

		var proposalId = 0;
		loop {
			proposalId := generateProposalId();
		} while {
			mapOfProposals.get(proposalId) != null;
		};

		let proposal : Proposal = {
			id = proposalId;
			content = content; // The content of the proposal
			creator = caller; // The member who created the proposal
			created = Time.now(); // The time the proposal was created
			executed = ?Time.now(); // The time the proposal was executed or null if not executed
			votes = []; // The votes on the proposal so far
			voteScore = 0; // A score based on the votes
			status = #Open; // The current status of the proposal
		};
		mapOfProposals.put(proposal.id, proposal);
		// Debug.print(debug_show(proposal.content));

		return #ok(proposal.id);
	};

	// 8. Get the proposal with the given id
	// Returns an error if the proposal does not exist
	public query func getProposal(id : ProposalId) : async Result<Proposal, Text> {
		return switch (mapOfProposals.get(id)) {
			case null #err("Proposal does not exist!");
			case (?proposal) #ok(proposal);
		};
	};

	// 9. Returns all the proposals
	public query func getAllProposal() : async [Proposal] {
		return Iter.toArray(mapOfProposals.vals());
	};

	/** 4. Voting System - Vote for the given proposal **/
	// 10. Vote for the given proposal
	// Returns an error if the proposal does not exist or the member is not allowed to vote
	public shared ({ caller }) func voteProposal(proposalId : ProposalId, yesOrNo : Bool) : async Result<(), Text> {
		let member = switch (members.get(caller)) {
			// Check caller is a member
			case null return #err("Not a member");
			case (?m) m;
		};
		// Only Graduates and Mentors are allowed to vote.
		if (verifyRole(member, #Student)) return #err("Not allowed to vote a proposal");
		let balance = await MBToken.balanceOf(caller);
		if (balance <= 0) return #err("Out of voting power");

		/// The voting power of a member is determined as follows:
		let leverageRate = if (member.role == #Mentor) { 5 } else if (member.role == #Graduate) {
			1;
		} else { 0 };
		let votingPower = leverageRate * balance;

		return switch (mapOfProposals.get(proposalId)) {
			case null #err("Proposal not exist");
			case (?proposal) {
				if (proposal.status != #Open) return #err("Proposal is not open for voting");
				let newVote : Vote = {
					member = caller;
					votingPower = votingPower;
					yesOrNo = yesOrNo;
				};
				for (vote in proposal.votes.vals()) {
					if (Principal.equal(caller, vote.member)) return #err("A member can only vote once per proposal.");
				};
				let newProposal = await _updateNewProposal(proposal, newVote);
				if (newProposal.status == #Accepted) {
					if (Result.isErr(await _executeProposal(newProposal.content))) {
						return #err("Fail to execute the proposal!");
					};
				};
				mapOfProposals.put(proposalId, newProposal);
				return #ok;
			};
		};
	};

	private func _executeProposal(content : ProposalContent) : async Result<(), Text> {
		return switch (content) {
			case (#ChangeManifesto(newManifesto)) {
				manifesto := newManifesto;
				await Webpage.setManifesto(manifesto , goals);

			};
			case (#AddGoal(newGoal)) {
				goals := _addToArray(goals, newGoal);
				await Webpage.setManifesto(manifesto, goals);
			};
			case (#AddMentor(pricipalId)) {
				_updateMember(pricipalId, #Graduate, #Mentor);
			};
		};
	};

	private func _executeHttpRequest() : async () {

	};

	private func _updateNewProposal(proposal : Proposal, newVote : Vote) : async Proposal {
		/// When a member votes on a proposal, his voting power is added or subtracted to the voteScore variable of the Proposal object.
		let newScore = proposal.voteScore + (if (newVote.yesOrNo) { newVote.votingPower } else { -newVote.votingPower });

		let newProposal : Proposal = {
			id = proposal.id;
			content = proposal.content; // The content of the proposal
			creator = proposal.creator; // The member who created the proposal
			created = proposal.created; // The time the proposal was created
			executed = proposal.executed; // The time the proposal was executed or null if not executed
			votes = _addToArray(proposal.votes, newVote); // The votes on the proposal so far
			voteScore = newScore; // A score based on the votes
			status = _updateProposalStatus(newScore); // The current status of the proposal
		};
		return newProposal;
	};

	private func _updateProposalStatus(score : Int) : ProposalStatus {
		return if (score >= 100) { #Accepted } else if (score <= -100) { #Rejected } else {
			#Open;
		};
	};

	// 11. Returns the Principal ID of the Webpage canister associated with this DAO canister
	public query func getIdWebpage() : async Principal {
		return canisterIdWebpage;
	};

	// Helper function
	// update a member to a new role, check the current role is qualified enough or not
	private func _updateMember(principalId : Principal, currentRole : Role, updateRole : Role) : Result<(), Text> {
		return switch (members.get(principalId)) {
			case null #err("Member does not exist");
			case (?mem) {
				if (mem.role != currentRole) return #err("Not qualified to be " # _roleToText(updateRole));

				let updateMember = { name = mem.name; role = updateRole };
				members.put(principalId, updateMember);
				#ok();
			};
		};
	};
	// add a new element to an array
	private func _addToArray<T>(arr : [T], e : T) : [T] {
		return List.toArray<T>(List.push<T>(e, List.fromArray<T>(arr)));
	};
	// convert the role type to text type
	private func _roleToText(r : Role) : Text {
		return switch (r) {
			case (#Student) "student";
			case (#Graduate) "graduate";
			case (#Mentor) "mentor";
		};
	};
	// Verify roles as arguments passed
	private func verifyRole(member : Member, role : Role) : Bool {
		return member.role == role;
	};

	/** System function to keep members and proposals persistent **/
	system func preupgrade() {
		memberEntries := Iter.toArray(members.entries());
		proposalEntries := Iter.toArray(mapOfProposals.entries());
	};
	system func postupgrade() {
		members := HashMap.fromIter<Principal, Member>(memberEntries.vals(), 1, Principal.equal, Principal.hash);
		mapOfProposals := HashMap.fromIter<ProposalId, Proposal>(proposalEntries.vals(), 1, Nat.equal, hashNat);

		/// 6. Initial Setup: Mentor: Name: motoko_bootcamp, Associated Principal: nkqop-siaaa-aaaaj-qa3qq-cai
		let firstMentor = Principal.fromText("2vxsx-fae");
		if (members.get(firstMentor) == null) {
			members.put(firstMentor, { name = "candidUi id"; role = #Mentor });
		};

		Debug.print(debug_show (members.get(firstMentor)));
	};

};
