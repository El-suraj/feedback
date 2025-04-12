import { createActor } from "../../declarations/FeedbackCanister";

export const getFeedbackActor = async () => {
  const authClient = await AuthClient.create();
  const identity = authClient.getIdentity();
  return createActor(process.env.FEEDBACK_CANISTER_ID, { agentOptions: { identity } });
};