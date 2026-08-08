import { getFirestore, doc, runTransaction, serverTimestamp } from "firebase/firestore";
// import { db } from "./firebase-config"; // Import your initialized firestore instance here

/**
 * Submit or Update a Quotation by the hardware shop.
 *
 * The shop only writes its own quotation document. quotationCount and the post
 * status are maintained server-side by the onQuotationSubmitted Cloud Function,
 * because security rules (correctly) forbid a shop from writing to a builder's
 * post.
 *
 * @param {Object} db - The initialized firestore database instance
 * @param {string} postId - The ID of the post the shop is bidding on
 * @param {Object} shopParams - Form data and shop details
 */
export async function submitQuotation(db, postId, shopParams) {
  const { shopId, shopName, ownerName, userId, message, estimatedTotal, deliveryFee, estimatedLeadTime, availableMaterials } = shopParams;

  const projectPostRef = doc(db, "projectPosts", postId);
  const quotationRef = doc(db, "projectPosts", postId, "quotations", shopId); // Upsert ID pattern (1 per shop)

  try {
    await runTransaction(db, async (transaction) => {
      const postDoc = await transaction.get(projectPostRef);
      if (!postDoc.exists()) throw new Error("Project does not exist!");

      const postData = postDoc.data();
      const postStatus = postData.status;
      if (postStatus === "closed" || postStatus === "awarded" || postStatus === "cancelled") {
        throw new Error("You can no longer submit quotations to this project.");
      }

      const quotationDoc = await transaction.get(quotationRef);
      const isNewQuotation = !quotationDoc.exists();

      // Always notify the builder who owns the post (not the shop account).
      const builderUserId = postData.userId || userId;

      // Setup the Quotation Document
      const quotationData = {
        shopId,
        shopName,
        ownerName,
        postId,
        userId: builderUserId,
        message,
        estimatedTotal: Number(estimatedTotal),
        deliveryFee: Number(deliveryFee),
        estimatedLeadTime,
        availableMaterials, // e.g., ["Cement", "Rebars"]
        status: "submitted",
        updatedAt: serverTimestamp(),
      };

      if (isNewQuotation) {
        quotationData.submittedAt = serverTimestamp();
      }

      transaction.set(quotationRef, quotationData, { merge: true });
    });

    console.log("Quotation successfully submitted!");
    return { success: true, message: "Quotation successfully submitted!" };
  } catch (error) {
    console.error("Quotation submission failed:", error);
    return { success: false, error: error.message };
  }
}
