// Cloud Functions entry point. Callables and triggers are exported here as each user story adds them.
export { completeRegistration } from "./callables/completeRegistration";
export { acceptPolicy } from "./callables/acceptPolicy";
export { createChild } from "./callables/createChild";
export { linkClinicChildren } from "./callables/linkClinicChildren";
export { onChildUpdated } from "./triggers/onChildUpdated";
export { syncPhoneNumber } from "./callables/syncPhoneNumber";
export { deleteAccount } from "./callables/deleteAccount";
export { touchSession } from "./callables/touchSession";
export { reverifyGuardian } from "./callables/reverifyGuardian";
export { createBooking } from "./callables/createBooking";
export { cancelBooking } from "./callables/cancelBooking";
export { changeBooking } from "./callables/changeBooking";
// Clinic dashboard (005): every staff change goes through these callables (research R3).
export { manageStaff, staffPasswordChanged } from "./callables/staff/manageStaff";
export { addWalkIn, queueAction, recordPayment, sellPackage, setWalkInsStopped } from "./callables/staff/queue";
export { staffBookingAction } from "./callables/staff/staffBookingAction";
export { openChildFile, saveDose, saveMeasurement, saveVisitNote, searchChildren, updateChildBasics } from "./callables/staff/childFile";
export { publishFollowUp, saveFollowUpDraft, updateCatalogue, updateClinic, updateSettings } from "./callables/staff/admin";
export { channelVideos, saveContent, saveContentCategories, setContentStatus } from "./callables/staff/content";
export { report } from "./callables/staff/report";
// Dashboard completion (009).
export { mergeChildren, registerFamily, staffLinkChildren, unlockReverify } from "./callables/staff/family";
