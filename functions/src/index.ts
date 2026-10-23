// Cloud Functions entry point. Callables and triggers are exported here as each user story adds them.
export { completeRegistration } from "./callables/completeRegistration";
export { acceptPolicy } from "./callables/acceptPolicy";
export { createChild } from "./callables/createChild";
export { linkClinicChildren } from "./callables/linkClinicChildren";
export { onChildUpdated } from "./triggers/onChildUpdated";
