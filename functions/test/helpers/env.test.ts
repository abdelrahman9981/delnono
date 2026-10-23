import { strict as assert } from "node:assert";
import { clearEmulators, signInAsPhoneUser, tokenClaims } from "./env";

describe("test harness", () => {
  beforeEach(clearEmulators);

  it("signs in a phone user whose ID token carries phone_number", async () => {
    const session = await signInAsPhoneUser("+201000000099");
    const claims = tokenClaims(session.idToken);
    assert.equal(claims.phone_number, "+201000000099");
    assert.equal(claims.user_id, session.uid);
  });
});
