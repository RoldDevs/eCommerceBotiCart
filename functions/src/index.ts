/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin (only if not already initialized)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

/**
 * Cloud Function to send push notifications when a notification request is
 * created. Listens to the 'notification_requests' collection in Firestore.
 */
export const sendNotification = onDocumentCreated(
  "notification_requests/{requestId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event");
      return null;
    }

    const data = snapshot.data();
    const {userId, title, body, data: notificationData} = data;

    try {
      // Get user's FCM token
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        logger.warn(`User document not found: ${userId}`);
        await snapshot.ref.update({
          status: "failed",
          error: "User not found",
        });
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        logger.warn(`No FCM token found for user: ${userId}`);
        // Mark request as failed
        await snapshot.ref.update({
          status: "failed",
          error: "No FCM token",
        });
        return null;
      }

      // Prepare notification payload
      const message: admin.messaging.Message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...notificationData,
          type: notificationData?.type || "general",
        },
        token: fcmToken,
        android: {
          priority: "high",
          notification: {
            channelId: "boticart_messages",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send notification
      const response = await admin.messaging().send(message);
      logger.info("Successfully sent message:", response);

      // Mark request as completed
      await snapshot.ref.update({
        status: "completed",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      logger.error("Error sending notification:", error);
      // Mark request as failed
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      await snapshot.ref.update({
        status: "failed",
        error: errorMessage,
      });
      return null;
    }
  }
);
