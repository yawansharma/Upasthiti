# 17 — Scalability Considerations

## Current Architecture Constraints

The application is built on a single Appwrite Cloud project with all collections in one database. The ML backend runs on Hugging Face Spaces free tier. There is no caching layer, no background job system, and no server-side processing. These are appropriate for a pilot/MVP deployment but impose limits at scale.

---

## Identified Scalability Bottlenecks

### 1. Attendance Log Volume

Attendance logs grow proportionally with the number of students × sessions per day × days of operation. The admin logs tab currently fetches up to 500 logs per class in a single network call, and some aggregation queries fetch 1,000+ documents.

**Behaviour at scale**: Query time increases linearly with log volume. Without server-side aggregation, the client is performing in-memory filtering and sorting on large datasets.

**Mitigation already implemented**: Cursor-based pagination (`Query.cursorAfter(lastDocId)`) is used in the admin logs tab, fetching 50 records at a time with infinite scroll.

**Recommended improvement**: Server-side aggregation via Appwrite Functions or a dedicated analytics collection that stores daily summaries.

---

### 2. `studentIds` Array in Classes

Each class stores a list of enrolled student IDs as an array field (`studentIds: Array<String>`). Appwrite document size limits and query performance will degrade as class sizes grow to hundreds or thousands of students.

**Recommended improvement**: Replace the array with a separate `class_enrollments` collection (one document per student-class pair) to support large class sizes and efficient querying.

---

### 3. ML Backend Cold Starts

The Hugging Face Spaces ML backend enters a sleep state after inactivity. The 3-attempt retry with backoff handles this, but the first attendance mark after a cold period takes 30–90 seconds from the user's perspective.

**Recommended improvement**: Move ML inference to a persistent, dedicated server (GPU VM, AWS SageMaker, or Google Vertex AI) with a keep-alive ping mechanism.

---

### 4. Realtime Subscription Coarseness

All Realtime subscriptions listen to the entire collection (any document change triggers a full re-fetch). As collections grow, this generates unnecessary network traffic: a log entry created in one department triggers a re-fetch of all logs for an admin in a different department.

**Recommended improvement**: Use Appwrite's query-scoped realtime (when available) or filter events client-side based on the `RealtimeMessage.payload` to avoid unnecessary full re-fetches.

---

### 5. No Background Job Infrastructure

Account cleanup, report generation, and data aggregation are all performed synchronously on the client during normal app operation. This works at small scale but will become a bottleneck as user counts grow.

**Recommended improvement**: Implement Appwrite Functions (Node.js or Dart) for:
- Scheduled nightly account cleanup
- Attendance summary pre-computation
- Notification dispatch (push notifications)

---

## Scaling Capacity Estimates (Rough)

Based on Appwrite Cloud's documented limits and the application's current query patterns:

| Metric | Comfortable Range | Concern Point |
|---|---|---|
| Concurrent users | Up to ~1,000 | Beyond 1,000, Realtime WebSocket connections may require plan upgrade |
| Classes per institution | Up to ~500 | No hard limit; query performance degrades beyond ~1,000 documents without indexes |
| Attendance logs | Up to ~100,000 | Beyond this, without pagination, initial loads become slow |
| Students per class | Up to ~200 (array limit) | Array-based enrollment list; beyond 200 needs schema change |
| Distribution events | Unlimited | No identified scaling issue |

---

## Horizontal Scalability

**Appwrite Cloud**: Automatically scales horizontally for reads. Appwrite manages this transparently.

**Flutter App**: Client-side horizontal scaling is not applicable. Mobile apps scale by distributing to more devices.

**ML Backend**: Single-instance; no horizontal scaling currently. This is the primary single point of failure in the system.

---

## Recommended Scalability Roadmap

1. **Near-term (0-3 months)**:
   - Replace `studentIds` array with a junction collection
   - Add Appwrite indexes on frequently-queried fields (timestamp, classId, userId, status)
   - Implement server-side log aggregation via Appwrite Function

2. **Medium-term (3-6 months)**:
   - Migrate ML backend to a persistent hosting environment
   - Add a Redis or in-memory caching layer for frequently-accessed read-only data (department lists, class metadata)
   - Implement push notifications for leave approvals and new class notifications (instead of relying on Realtime WebSocket)

3. **Long-term (6-12 months)**:
   - Multi-tenant architecture to support multiple independent institutions on a single deployment
   - Dedicated analytics database with pre-computed aggregates
   - Appwrite self-hosted deployment with custom hardware for compliance-sensitive institutions
