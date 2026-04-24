import { getFirestore, doc, runTransaction, serverTimestamp } from "firebase/firestore";
// import { db } from "./firebase-config"; // Import your initialized firestore instance here

/**
 * Submit or Update a Quotation by the hardware shop.
 * Automatically updates the quotationCount of the projectPost via a secure transaction.
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
      
      const postStatus = postDoc.data().status;
      if (postStatus === "closed" || postStatus === "awarded" || postStatus === "cancelled") {
        throw new Error("You can no longer submit quotations to this project.");
      }

      const quotationDoc = await transaction.get(quotationRef);
      const isNewQuotation = !quotationDoc.exists();

      // Setup the Quotation Document
      const quotationData = {
        shopId,
        shopName,
        ownerName,
        postId,
        userId,
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

      // Only increment count and change status if it is a NEW quotation (not a shop updating their previous bid)
      if (isNewQuotation) {
        const newCount = (postDoc.data().quotationCount || 0) + 1;
        transaction.update(projectPostRef, {
          quotationCount: newCount,
          status: "has_quotations"
        });
      }
    });

    console.log("Quotation successfully submitted!");
    return { success: true, message: "Quotation successfully submitted!" };
  } catch (error) {
    console.error("Quotation submission failed:", error);
    return { success: false, error: error.message };
  }
}
