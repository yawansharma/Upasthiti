const sdk = require("node-appwrite");

// ============================================================
// CONFIGURATION
// ============================================================

// ---------- SOURCE ----------
const SOURCE_PROJECT_ID = "6a2c0bd800121a164e77";
const SOURCE_API_KEY = "standard_cdb58267add612e22e7ec99435cf3ecb7fb5c3bda006f61f48fc43db0d3e6d802e0523edb44cae7d6684a08b63051220afa57110d1ece6a263ff9438a15a4d46f9ba69eb92d5d1130993a4b0cc5d3725c789a1becb7b70e24883570d46dab36b7356568b524f8cfe7fcb7a369f69306e13a0ae34167c5547e677f65e7bacc996";
const SOURCE_DATABASE_ID = "6a2c10dc000d5e50f314";

// ---------- DESTINATION ----------
const DEST_PROJECT_ID = "6ac4f7a50037e9fe4dfa";
const DEST_API_KEY = "standard_dd21d371e41f2349b390de6242c47ebf3cad40b01845113ddc974d6bb8734b64fa741b79c98049d0355bf9eb0941d48f6b7002e98f960a3c807f5439b24cfafab7a4a51d69b4f5adcd179e0e110b554f1474a2bff46b5599b56edd9116b6577d1b656939e31c770d6bcc006fee282a4472558713b422b235ff1c33285f22a406";
const DEST_DATABASE_ID = "6ac510390009fba397c7";

// ============================================================
// CLIENTS
// ============================================================

const sourceClient = new sdk.Client()
    .setEndpoint("https://sgp.cloud.appwrite.io/v1")
    .setProject(SOURCE_PROJECT_ID)
    .setKey(SOURCE_API_KEY);

const destClient = new sdk.Client()
    .setEndpoint("https://fra.cloud.appwrite.io/v1")
    .setProject(DEST_PROJECT_ID)
    .setKey(DEST_API_KEY);

const sourceDB = new sdk.Databases(sourceClient);
const destDB = new sdk.Databases(destClient);

// ============================================================
// SETTINGS
// ============================================================

const sleep = ms =>
    new Promise(resolve => setTimeout(resolve, ms));

const PAGE_SIZE = 100;

let stats = {
    collections: 0,
    attributes: 0,
    indexes: 0,
    documents: 0,
    failedCollections: 0,
    failedAttributes: 0,
    failedIndexes: 0,
    failedDocuments: 0
};

// ============================================================
// PAGINATION
// ============================================================

async function getAllCollections() {

    const result = [];
    let cursor = null;

    while (true) {

        const queries = [
            sdk.Query.limit(PAGE_SIZE)
        ];

        if (cursor) {
            queries.push(
                sdk.Query.cursorAfter(cursor)
            );
        }

        const response =
            await sourceDB.listCollections(
                SOURCE_DATABASE_ID,
                queries
            );

        result.push(...response.collections);

        if (response.collections.length < PAGE_SIZE) {
            break;
        }

        cursor =
            response.collections[
                response.collections.length - 1
            ].$id;
    }

    return result;
}


// ============================================================
// GET ALL DOCUMENTS
// ============================================================

async function getAllDocuments(collectionId) {

    const result = [];
    let cursor = null;

    while (true) {

        const queries = [
            sdk.Query.limit(PAGE_SIZE)
        ];

        if (cursor) {
            queries.push(
                sdk.Query.cursorAfter(cursor)
            );
        }

        const response =
            await sourceDB.listDocuments(
                SOURCE_DATABASE_ID,
                collectionId,
                queries
            );

        result.push(...response.documents);

        if (response.documents.length < PAGE_SIZE) {
            break;
        }

        cursor =
            response.documents[
                response.documents.length - 1
            ].$id;
    }

    return result;
}


// ============================================================
// GET ALL INDEXES
// ============================================================

async function getAllIndexes(collectionId) {

    const result = [];
    let cursor = null;

    while (true) {

        const queries = [
            sdk.Query.limit(PAGE_SIZE)
        ];

        if (cursor) {
            queries.push(
                sdk.Query.cursorAfter(cursor)
            );
        }

        const response =
            await sourceDB.listIndexes(
                SOURCE_DATABASE_ID,
                collectionId,
                queries
            );

        result.push(...response.indexes);

        if (response.indexes.length < PAGE_SIZE) {
            break;
        }

        cursor =
            response.indexes[
                response.indexes.length - 1
            ].$id;
    }

    return result;
}


// ============================================================
// COPY ATTRIBUTE
// ============================================================

async function copyAttribute(collection, attr) {

    console.log(
        `    Attribute: ${attr.key} (${attr.type})`
    );

    try {

        switch (attr.type) {

            // ------------------------------------------------
            // STRING
            // ------------------------------------------------

            case "string":

                await destDB.createStringAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.size,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array,
                    attr.encrypt
                );

                break;


            // ------------------------------------------------
            // INTEGER
            // ------------------------------------------------

            case "integer":

                await destDB.createIntegerAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.required,
                    attr.min,
                    attr.max,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // FLOAT
            // ------------------------------------------------

            case "float":

                await destDB.createFloatAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.required,
                    attr.min,
                    attr.max,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // BOOLEAN
            // ------------------------------------------------

            case "boolean":

                await destDB.createBooleanAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // DATETIME
            // ------------------------------------------------

            case "datetime":

                await destDB.createDatetimeAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // EMAIL
            // ------------------------------------------------

            case "email":

                await destDB.createEmailAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // URL
            // ------------------------------------------------

            case "url":

                await destDB.createUrlAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // IP
            // ------------------------------------------------

            case "ip":

                await destDB.createIpAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // TEXT
            // ------------------------------------------------

            case "text":

                await destDB.createStringAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.size || 65535,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array,
                    attr.encrypt
                );

                break;


            // ------------------------------------------------
            // ENUM
            // ------------------------------------------------

            case "enum":

                await destDB.createEnumAttribute(
                    DEST_DATABASE_ID,
                    collection.$id,
                    attr.key,
                    attr.elements,
                    attr.required,
                    attr.required
                        ? undefined
                        : attr.default,
                    attr.array
                );

                break;


            // ------------------------------------------------
            // RELATIONSHIP
            // ------------------------------------------------

            case "relationship":

                console.log(
                    `    ⚠ Relationship attribute detected: ${attr.key}`
                );

                console.log(
                    `      Related collection: ${attr.relatedCollection}`
                );

                console.log(
                    `      Relationship type: ${attr.relationType}`
                );

                /*
                 * Relationships should be created AFTER
                 * all collections exist.
                 *
                 * They are handled separately below.
                 */

                break;


            // ------------------------------------------------
            // UNKNOWN
            // ------------------------------------------------

            default:

                console.log(
                    `    ⚠ Unsupported attribute type: ${attr.type}`
                );

                stats.failedAttributes++;

                return;
        }

        stats.attributes++;

    } catch (error) {

        stats.failedAttributes++;

        console.error(
            `    ✗ Failed attribute ${attr.key}`
        );

        console.error(
            `      ${error.message}`
        );
    }

    await sleep(500);
}


// ============================================================
// COPY ALL ATTRIBUTES
// ============================================================

async function copyAttributes(collection) {

    console.log(
        `  Creating attributes...`
    );

    for (const attr of collection.attributes) {

        await copyAttribute(
            collection,
            attr
        );
    }

    // Appwrite needs time to finish schema operations
    await sleep(2000);
}


// ============================================================
// COPY INDEXES
// ============================================================

async function copyIndexes(collection) {

    console.log(
        `  Copying indexes...`
    );

    let indexes;

    try {

        indexes =
            await getAllIndexes(collection.$id);

    } catch (error) {

        console.error(
            `  ✗ Could not read indexes: ${error.message}`
        );

        return;
    }

    for (const index of indexes) {

        try {

            console.log(
                `    Index: ${index.key}`
            );

            await destDB.createIndex(
                DEST_DATABASE_ID,
                collection.$id,
                index.key,
                index.type,
                index.attributes,
                index.orders
            );

            stats.indexes++;

        } catch (error) {

            stats.failedIndexes++;

            console.error(
                `    ✗ Failed index ${index.key}:`
            );

            console.error(
                `      ${error.message}`
            );
        }

        await sleep(1000);
    }

    await sleep(1500);
}


// ============================================================
// REMOVE APPWRITE SYSTEM FIELDS
// ============================================================

function cleanDocument(doc) {

    const data = {
        ...doc
    };

    delete data.$id;
    delete data.$permissions;
    delete data.$createdAt;
    delete data.$updatedAt;
    delete data.$databaseId;
    delete data.$collectionId;

    return data;
}


// ============================================================
// COPY DOCUMENTS
// ============================================================

async function copyDocuments(collection) {

    console.log(
        `  Copying documents...`
    );

    let documents;

    try {

        documents =
            await getAllDocuments(
                collection.$id
            );

    } catch (error) {

        console.error(
            `  ✗ Could not read documents: ${error.message}`
        );

        stats.failedDocuments++;

        return;
    }

    console.log(
        `    Found ${documents.length} documents`
    );

    for (const doc of documents) {

        try {

            const data =
                cleanDocument(doc);

            const permissions =
                doc.$permissions || [];

            await destDB.createDocument(
                DEST_DATABASE_ID,
                collection.$id,
                doc.$id,
                data,
                permissions
            );

            stats.documents++;

            console.log(
                `    ✓ ${doc.$id}`
            );

        } catch (error) {

            stats.failedDocuments++;

            console.error(
                `    ✗ ${doc.$id}`
            );

            console.error(
                `      ${error.message}`
            );
        }
    }
}


// ============================================================
// CREATE COLLECTION
// ============================================================

async function createCollection(collection) {

    console.log(
        `\n---------------------------------------------`
    );

    console.log(
        `Collection: ${collection.name}`
    );

    console.log(
        `ID: ${collection.$id}`
    );

    try {

        await destDB.createCollection(
            DEST_DATABASE_ID,
            collection.$id,
            collection.name,
            collection.$permissions || [],
            collection.documentSecurity
        );

        stats.collections++;

        console.log(
            `  ✓ Collection created`
        );

    } catch (error) {

        console.log(
            `  ⚠ Collection creation failed/already exists`
        );

        console.log(
            `    ${error.message}`
        );

        stats.failedCollections++;
    }
}


// ============================================================
// MAIN MIGRATION
// ============================================================

async function migrate() {

    console.log(`
============================================================
             APPWRITE DATABASE MIGRATION
============================================================

Source project:
${SOURCE_PROJECT_ID}

Source database:
${SOURCE_DATABASE_ID}

Destination project:
${DEST_PROJECT_ID}

Destination database:
${DEST_DATABASE_ID}

============================================================
`);

    // --------------------------------------------------------
    // GET COLLECTIONS
    // --------------------------------------------------------

    console.log(
        "Reading source collections..."
    );

    const collections =
        await getAllCollections();

    console.log(
        `Found ${collections.length} collections.\n`
    );


    // --------------------------------------------------------
    // PHASE 1
    // CREATE ALL COLLECTIONS FIRST
    // --------------------------------------------------------

    console.log(
        "PHASE 1 — Creating collections"
    );

    for (const collection of collections) {

        await createCollection(
            collection
        );
    }


    // --------------------------------------------------------
    // PHASE 2
    // CREATE ATTRIBUTES
    // --------------------------------------------------------

    console.log(
        "\nPHASE 2 — Creating attributes"
    );

    for (const collection of collections) {

        await copyAttributes(
            collection
        );
    }


    // --------------------------------------------------------
    // PHASE 3
    // CREATE INDEXES
    // --------------------------------------------------------

    console.log(
        "\nPHASE 3 — Creating indexes"
    );

    for (const collection of collections) {

        await copyIndexes(
            collection
        );
    }


    // --------------------------------------------------------
    // PHASE 4
    // COPY DOCUMENTS
    // --------------------------------------------------------

    console.log(
        "\nPHASE 4 — Copying documents"
    );

    for (const collection of collections) {

        await copyDocuments(
            collection
        );
    }


    // --------------------------------------------------------
    // SUMMARY
    // --------------------------------------------------------

    console.log(`
============================================================
                  MIGRATION COMPLETE
============================================================

Collections created : ${stats.collections}
Attributes created  : ${stats.attributes}
Indexes created     : ${stats.indexes}
Documents copied    : ${stats.documents}

Failed collections  : ${stats.failedCollections}
Failed attributes   : ${stats.failedAttributes}
Failed indexes      : ${stats.failedIndexes}
Failed documents    : ${stats.failedDocuments}

============================================================
`);
}


// ============================================================
// RUN
// ============================================================

migrate()
    .catch(error => {

        console.error(
            "\n❌ MIGRATION FAILED"
        );

        console.error(
            error
        );

        process.exit(1);
    });