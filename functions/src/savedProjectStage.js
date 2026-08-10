/**
 * Planning/canvassing stage helpers for saved estimates.
 *
 * Kept pure so Cloud Function triggers and unit tests share the same
 * "never move backwards" guard used by advanceSavedProject.
 */

const SAVED_PROJECT_STAGES = [
  "draft",
  "planning",
  "waiting for quotations",
  "receiving quotations",
  "supplier selected",
  "completed",
];

const LEGACY_STAGE_ALIASES = {
  "": 0,
  ready: 1,
  posted: 2,
  open: 2,
  has_quotations: 3,
  offer_accepted: 4,
  awarded: 4,
};

function savedProjectStage(status) {
  const value = String(status || "").toLowerCase().trim();
  const index = SAVED_PROJECT_STAGES.indexOf(value);
  if (index >= 0) return index;
  const alias = LEGACY_STAGE_ALIASES[value];
  return typeof alias === "number" ? alias : 0;
}

/**
 * Whether a trigger may write [targetStage] over the stored status.
 * Completed cycles are frozen; equal/lower stages are no-ops.
 */
function canAdvanceSavedProjectStage(currentStatus, targetStage) {
  const currentStage = savedProjectStage(currentStatus);
  if (currentStage >= SAVED_PROJECT_STAGES.length - 1) return false;
  if (currentStage >= targetStage) return false;
  return true;
}

module.exports = {
  SAVED_PROJECT_STAGES,
  savedProjectStage,
  canAdvanceSavedProjectStage,
};
