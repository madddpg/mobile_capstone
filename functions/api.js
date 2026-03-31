"use strict";

const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");

// admin.initializeApp() is called in index.js. Here we only reuse it.
const db = admin.firestore();

function normalizeKey(value) {
  return String(value || "").trim().toLowerCase();
}

async function resolveProjectIdByQuery(projectQuery) {
  const key = normalizeKey(projectQuery);
  if (!key) return null;

  // Prefer a stable slug field.
  const bySlug = await db
    .collection("projects")
    .where("slug", "==", key)
    .limit(1)
    .get();

  if (!bySlug.empty) {
    return bySlug.docs[0].id;
  }

  // Fallback: match a normalized name field.
  const byNameLower = await db
    .collection("projects")
    .where("name_lower", "==", key)
    .limit(1)
    .get();

  if (!byNameLower.empty) {
    return byNameLower.docs[0].id;
  }

  return null;
}

async function resolveCategoryDoc(categoryId, categoryName, projectId) {
  const id = String(categoryId || "").trim();
  if (id) {
    const doc = await db.collection("categories").doc(id).get();
    if (doc.exists) return doc;
  }

  const nameKey = normalizeKey(categoryName);
  if (!nameKey) return null;

  let query = db.collection("categories").where("name_lower", "==", nameKey);
  if (projectId) query = query.where("project_id", "==", projectId);

  const snap = await query.limit(1).get();
  if (snap.empty) return null;
  return snap.docs[0];
}

const app = express();
app.use(cors({ origin: true }));

app.get("/health", (req, res) => {
  res.status(200).json({ ok: true });
});

// GET /categories?project=bathroom
app.get("/categories", async (req, res) => {
  try {
    const projectQuery = req.query.project;
    if (!projectQuery) {
      return res.status(400).json({ error: "Missing required query param: project" });
    }

    const projectId = await resolveProjectIdByQuery(projectQuery);
    if (!projectId) {
      return res.status(404).json({ error: "Project not found" });
    }

    const categoriesSnap = await db
      .collection("categories")
      .where("project_id", "==", projectId)
      .get();

    const categories = categoriesSnap.docs
      .map((doc) => {
      const data = doc.data() || {};
      return {
        id: doc.id,
        name: String(data.name || ""),
        type: data.type ? String(data.type) : null,
        order: Number.isFinite(Number(data.order)) ? Number(data.order) : 0,
      };
      })
      .sort((a, b) => {
        if (a.order !== b.order) return a.order - b.order;
        return a.name.localeCompare(b.name);
      })
      .map(({ order, ...rest }) => rest);

    return res.status(200).json({ project_id: projectId, categories });
  } catch (error) {
    return res.status(500).json({ error: "Internal error" });
  }
});

// GET /materials?category=Floor%20Surface
// or  /materials?categoryId=<docId>
// Optional: &project=bathroom (for category name disambiguation)
app.get("/materials", async (req, res) => {
  try {
    const categoryId = req.query.categoryId;
    const categoryName = req.query.category;

    if (!categoryId && !categoryName) {
      return res.status(400).json({ error: "Missing required query param: categoryId or category" });
    }

    let projectId = null;
    if (req.query.project) {
      projectId = await resolveProjectIdByQuery(req.query.project);
    }

    const categoryDoc = await resolveCategoryDoc(categoryId, categoryName, projectId);
    if (!categoryDoc) {
      return res.status(404).json({ error: "Category not found" });
    }

    const categoryData = categoryDoc.data() || {};
    const resolvedCategoryName = String(categoryData.name || "");

    const materialsSnap = await db
      .collection("materials")
      .where("category_id", "==", categoryDoc.id)
      .get();

    const all = materialsSnap.docs.map((doc) => {
      const data = doc.data() || {};
      return {
        id: doc.id,
        name: String(data.name || ""),
        description: String(data.description || ""),
        category: resolvedCategoryName,
        is_recommended: Boolean(data.is_recommended),
        image_url: data.image_url ? String(data.image_url) : null,
      };
    });

    const recommended = all
      .filter((m) => m.is_recommended)
      .slice(0, 3);

    const alternatives = all
      .filter((m) => !m.is_recommended);

    return res.status(200).json({
      category: resolvedCategoryName,
      category_id: categoryDoc.id,
      recommended,
      alternatives,
    });
  } catch (error) {
    return res.status(500).json({ error: "Internal error" });
  }
});

module.exports = { app };
