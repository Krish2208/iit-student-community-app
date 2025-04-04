const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { getMessaging } = require("firebase-admin/messaging");

admin.initializeApp();

exports.notifyNewEvent = functions.firestore
  .document("events/{eventId}")
  .onCreate(async (snapshot, context) => {
    const eventData = snapshot.data();
    const eventId = context.params.eventId;
    const organizerId = eventData.organizerId; // Club ID

    if (!organizerId) {
      console.log("Missing organizerId in event data");
      return null;
    }

    try {
      // Get club information
      const clubDoc = await admin
        .firestore()
        .collection("clubs")
        .doc(organizerId)
        .get();

      if (!clubDoc.exists) {
        console.log("Club not found with ID:", organizerId);
        return null;
      }

      const clubData = clubDoc.data();

      // Format date for notification
      let eventDate = "soon";
      if (eventData.dateTime) {
        try {
          const date = eventData.dateTime.toDate();
          const options = {
            month: "short",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
          };
          eventDate = date.toLocaleDateString("en-US", options);
        } catch (error) {
          console.error("Error formatting date:", error);
          // Keep default value if date formatting fails
        }
      }

      // Create notification message
      const notificationTitle = `New Event: ${eventData.name || "Untitled Event"}`;
      const notificationBody = `${clubData.name || "A club"} is organizing "${
        eventData.name || "an event"
      }" at ${eventData.location || "TBD"} on ${eventDate}`;

      // Create the message
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          eventId: eventId,
          clubId: organizerId,
          type: "new_event",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        topic: `club_${organizerId}`,
      };

      // Send the message
      const fcmResponse = await getMessaging().send(message);
      console.log("Successfully sent message:", fcmResponse);

      // Also store in Firestore for notification history
      const subscribers = clubData.subscribers || [];
      
      if (subscribers.length > 0) {
        const batch = admin.firestore().batch();
        const maxBatchSize = 500; // Firestore batch write limit
        
        for (let i = 0; i < subscribers.length; i += maxBatchSize) {
          const currentBatch = subscribers.slice(i, i + maxBatchSize);
          const currentBatchObj = admin.firestore().batch();
          
          for (const userId of currentBatch) {
            if (!userId) continue; // Skip empty user IDs
            
            const notificationRef = admin
              .firestore()
              .collection("notifications")
              .doc();
              
            currentBatchObj.set(notificationRef, {
              userId: userId,
              title: notificationTitle,
              body: notificationBody,
              eventId: eventId,
              clubId: organizerId,
              photoUrl: clubData.photoUrl || null,
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              type: "new_event"
            });
          }
          
          await currentBatchObj.commit();
        }
      }

      return null;
    } catch (error) {
      console.error("Error sending notifications:", error);
      return null;
    }
  });