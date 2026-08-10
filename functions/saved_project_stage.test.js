const test = require("node:test");
const assert = require("node:assert/strict");
const {
  SAVED_PROJECT_STAGES,
  savedProjectStage,
  canAdvanceSavedProjectStage,
} = require("./src/savedProjectStage");

test("savedProjectStage maps canonical and legacy statuses", () => {
  assert.equal(savedProjectStage("receiving quotations"), 3);
  assert.equal(savedProjectStage("has_quotations"), 3);
  assert.equal(savedProjectStage("supplier selected"), 4);
  assert.equal(savedProjectStage("offer_accepted"), 4);
  assert.equal(savedProjectStage("completed"), 5);
});

test("canAdvanceSavedProjectStage never moves backwards past supplier selected", () => {
  const receiving = SAVED_PROJECT_STAGES.indexOf("receiving quotations");
  const supplierSelected = SAVED_PROJECT_STAGES.indexOf("supplier selected");

  // Accept won the race: receiving trigger must not regress the estimate.
  assert.equal(
    canAdvanceSavedProjectStage("supplier selected", receiving),
    false,
  );
  assert.equal(
    canAdvanceSavedProjectStage("offer_accepted", receiving),
    false,
  );

  // Waiting → receiving is still allowed.
  assert.equal(
    canAdvanceSavedProjectStage("waiting for quotations", receiving),
    true,
  );

  // Receiving → supplier selected is allowed.
  assert.equal(
    canAdvanceSavedProjectStage("receiving quotations", supplierSelected),
    true,
  );

  // Completed stays frozen.
  assert.equal(
    canAdvanceSavedProjectStage("completed", supplierSelected),
    false,
  );
});
