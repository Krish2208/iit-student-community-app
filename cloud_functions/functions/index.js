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

      // Send the message with retry
      try {
        const fcmResponse = await getMessaging().send(message);
        console.log("Successfully sent message:", fcmResponse);
      } catch (fcmError) {
        console.error("FCM send error:", fcmError);
        
        // If topic messaging failed, try to send to individual tokens as fallback
        if (clubData.subscribers && clubData.subscribers.length > 0) {
          try {
            // Get tokens for all subscribers
            const tokenSnapshots = await Promise.all(
              clubData.subscribers.map(userId => 
                admin.firestore().collection('users').doc(userId).get()
              )
            );
            
            const tokens = [];
            tokenSnapshots.forEach(doc => {
              if (doc.exists && doc.data().fcmTokens) {
                tokens.push(...doc.data().fcmTokens);
              }
            });
            
            if (tokens.length > 0) {
              // Send in batches of 500
              const tokenChunks = [];
              for (let i = 0; i < tokens.length; i += 500) {
                tokenChunks.push(tokens.slice(i, i + 500));
              }
              
              await Promise.all(tokenChunks.map(chunk => {
                const multicastMessage = {
                  ...message,
                  tokens: chunk,
                };
                delete multicastMessage.topic;
                return getMessaging().sendMulticast(multicastMessage);
              }));
              
              console.log("Sent fallback individual notifications");
            }
          } catch (tokenError) {
            console.error("Token fallback error:", tokenError);
          }
        }
      }

      // Store a single notification document with a map of read statuses
      const notificationRef = admin
        .firestore()
        .collection("notifications")
        .doc();
      
      const subscribers = clubData.subscribers || [];
      const readStatusMap = {};
      
      // Initialize read status for all subscribers
      subscribers.forEach(userId => {
        if (userId) {
          readStatusMap[userId] = false;
        }
      });
      
      await notificationRef.set({
        title: notificationTitle,
        body: notificationBody,
        eventId: eventId,
        clubId: organizerId,
        photoUrl: clubData.photoUrl || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        type: "new_event",
        readStatus: readStatusMap
      });

      return null;
    } catch (error) {
      console.error("Error sending notifications:", error);
      return null;
    }
  });