const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");
const sendgrid = require("@sendgrid/mail");
const twilio = require("twilio");
admin.initializeApp();

const db = admin.firestore();
const openAiKey = defineSecret("OPENAI_API_KEY");
const sendGridKey = defineSecret("SENDGRID_API_KEY");
const twilioSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioPhone = defineSecret("TWILIO_PHONE_NUMBER");
exports.generateFutureLetter = onCall(
  { secrets: [openAiKey] },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const rawMessage = request.data?.rawMessage;

    if (!rawMessage || rawMessage.trim().length < 5) {
      throw new HttpsError("invalid-argument", "Message is too short.");
    }

    const openai = new OpenAI({ apiKey: openAiKey.value() });

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "You write heartfelt future letters for a memory app called TYMEFLY. Keep it warm, emotional, clear, and not too long. Do not mention AI.",
        },
        {
          role: "user",
          content: `Turn this rough message into a meaningful future letter:\n\n${rawMessage}`,
        },
      ],
    });

    return {
      letter: completion.choices[0]?.message?.content || "",
    };
  }
);

exports.releaseDueTymeFlys = onSchedule(
  "every 15 minutes",
  async () => {
    const now = admin.firestore.Timestamp.now();

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken || "";

      const capsulesSnap = await userDoc.ref
        .collection("capsules")
        .where("status", "==", "scheduled")
        .where("releaseDate", "<=", now)
        .limit(20)
        .get();

      for (const capsuleDoc of capsulesSnap.docs) {
        await capsuleDoc.ref.update({
          status: "delivered",
          deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (userData.notificationsEnabled !== false && fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "A TYMEFLY was released",
              body: "One of your future memories is now unlocked.",
            },
            data: {
              capsuleId: capsuleDoc.id,
              type: "tymefly_released",
            },
          });
        }
      }
    }

    return null;
  }
);

exports.generateMemoryMovie = onCall(
  { secrets: [openAiKey] },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const rawMessage = request.data?.rawMessage;

    if (!rawMessage || rawMessage.trim().length < 5) {
      throw new HttpsError("invalid-argument", "Memory description is too short.");
    }

    const openai = new OpenAI({
      apiKey: openAiKey.value(),
    });

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "You create cinematic memory movie plans for an app called TYMEFLY. Keep it emotional, clean, and easy to follow. Do not mention AI.",
        },
        {
          role: "user",
          content: `Create a memory movie plan from this memory description:\n\n${rawMessage}`,
        },
      ],
    });

    const moviePlan = completion.choices[0]?.message?.content || "";

    return { moviePlan };
  }
);


exports.generateVoiceNarration = onCall(
  { secrets: [openAiKey] },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const rawMessage = request.data?.rawMessage;

    if (!rawMessage || rawMessage.trim().length < 5) {
      throw new HttpsError("invalid-argument", "Memory description is too short.");
    }

    const openai = new OpenAI({
      apiKey: openAiKey.value(),
    });

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "You write heartfelt voiceover narration scripts for TYMEFLY future memories. Keep it warm, emotional, clear, and ready to be read aloud. Do not mention AI.",
        },
        {
          role: "user",
          content: `Create a voice narration script from this memory:\n\n${rawMessage}`,
        },
      ],
    });

    const narration = completion.choices[0]?.message?.content || "";

    return { narration };
  }
);

exports.generateSmartStoryline = onCall(
  { secrets: [openAiKey] },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const rawMessage = request.data?.rawMessage;

    if (!rawMessage || rawMessage.trim().length < 5) {
      throw new HttpsError("invalid-argument", "Memory description is too short.");
    }

    const openai = new OpenAI({
      apiKey: openAiKey.value(),
    });

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "You organize memories into a meaningful future storyline for TYMEFLY. Create a clear emotional timeline with sections. Do not mention AI.",
        },
        {
          role: "user",
          content: `Create a smart future storyline from this memory:\n\n${rawMessage}`,
        },
      ],
    });

    const storyline = completion.choices[0]?.message?.content || "";

    return { storyline };
  }
);

exports.summarizeAlbum = onCall(
  { secrets: [openAiKey] },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const rawMessage = request.data?.rawMessage;

    if (!rawMessage || rawMessage.trim().length < 5) {
      throw new HttpsError("invalid-argument", "Album details are too short.");
    }

    const openai = new OpenAI({
      apiKey: openAiKey.value(),
    });

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "You summarize photo and video albums for a future memory app called TYMEFLY. Create a warm, emotional story summary based on the album items. Do not mention AI.",
        },
        {
          role: "user",
          content: `Summarize this album into a meaningful future memory story:\n\n${rawMessage}`,
        },
      ],
    });

    const summary = completion.choices[0]?.message?.content || "";

    return { summary };
  }
);

exports.testTymeflyEmail = onCall(
  { secrets: [sendGridKey] },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const to = request.data?.to;

    if (!to) {
      throw new HttpsError("invalid-argument", "Recipient email is required.");
    }

    sendgrid.setApiKey(sendGridKey.value());

    await sendgrid.send({
      to,
      from: {
        email: "noreply@an2app.com",
        name: "TYMEFLY",
      },
      replyTo: "alerttmenow@gmail.com",
      subject: "TYMEFLY test email",
      html: `
        <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111827;">
          <h2>TYMEFLY email is working</h2>
          <p>This is a test email from TYMEFLY.</p>
          <p>If you received this, trusted contact email notifications can be connected next.</p>
        </div>
      `,
    });

    return { ok: true };
  }
);

exports.sendTymeflyReleaseEmail = onCall(
  { secrets: [sendGridKey] },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const to = request.data?.to;
    const recipientName = request.data?.recipientName || "there";
    const senderName = request.data?.senderName || "Someone special";
    const message = request.data?.message || "";
    const mediaUrl = request.data?.mediaUrl || "";

    if (!to) {
      throw new HttpsError("invalid-argument", "Recipient email is required.");
    }

    sendgrid.setApiKey(sendGridKey.value());

    await sendgrid.send({
      to,
      from: {
        email: "noreply@an2app.com",
        name: "TYMEFLY",
      },
      replyTo: "alerttmenow@gmail.com",
      subject: "A TYMEFLY memory has been released for you",
      html: `
        <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111827;max-width:620px;margin:0 auto;padding:24px;">
          <h2 style="color:#6D4CFF;">A TYMEFLY memory has been released</h2>
          <p>Hi ${recipientName},</p>
          <p>${senderName} created a future memory for you, and it has now been released.</p>
          ${message ? `<div style="background:#F7F5FF;border:1px solid #EDE7FF;border-radius:16px;padding:16px;margin:18px 0;">${message}</div>` : ""}
          ${mediaUrl ? `<p><a href="${mediaUrl}" style="background:#6D4CFF;color:white;padding:12px 18px;border-radius:12px;text-decoration:none;display:inline-block;">Open Memory</a></p>` : ""}
          <p style="color:#6B7280;font-size:13px;margin-top:24px;">Sent with TYMEFLY — future memories, delivered with love.</p>
        </div>
      `,
    });

    return { ok: true };
  }
);


exports.emailReleasedTymeFlys = onSchedule(
  { schedule: "every 15 minutes", secrets: [sendGridKey] },
  async () => {
    sendgrid.setApiKey(sendGridKey.value());

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      const senderName = userData.username || userData.email || "Someone special";

      const releasedSnap = await userDoc.ref
        .collection("capsules")
        .where("releaseDate", "<=", admin.firestore.Timestamp.now())
        .where("emailSent", "==", false)
        .limit(20)
        .get();

      for (const capsuleDoc of releasedSnap.docs) {
        const capsule = capsuleDoc.data();
        const recipients = capsule.recipients || [];

        for (const recipient of recipients) {
          const to = recipient.email || "";
          if (!to) continue;

          await sendgrid.send({
            to,
            from: {
              email: "noreply@an2app.com",
              name: "TYMEFLY",
            },
            replyTo: "alerttmenow@gmail.com",
            trackingSettings: {
              clickTracking: {
                enable: false,
                enableText: false,
              },
            },
            subject: "A TYMEFLY memory has been released for you",
            html: `
              <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111827;max-width:620px;margin:0 auto;padding:24px;">
                <h2 style="color:#6D4CFF;">A TYMEFLY memory has been released</h2>
                <p>Hi ${recipient.name || "there"},</p>
                <p>${senderName} created a future memory for you, and it has now been released.</p>
                ${capsule.message ? `<div style="background:#F7F5FF;border:1px solid #EDE7FF;border-radius:16px;padding:16px;margin:18px 0;">${capsule.message}</div>` : ""}
                ${capsule.mediaUrl ? `<p><a href="${capsule.mediaUrl}" style="background:#6D4CFF;color:white;padding:12px 18px;border-radius:12px;text-decoration:none;display:inline-block;">Open Memory</a></p>` : ""}
                <p style="color:#6B7280;font-size:13px;margin-top:24px;">Sent with TYMEFLY — future memories, delivered with love.</p>
              </div>
            `,
          });
        }

        await capsuleDoc.ref.update({
          emailSent: true,
          emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    return null;
  }
);

exports.smsReleasedTymeFlys = onSchedule(
  {
    schedule: "every 15 minutes",
    secrets: [twilioSid, twilioToken, twilioPhone],
  },
  async () => {

    const client = twilio(
      twilioSid.value(),
      twilioToken.value()
    );

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {

      const userData = userDoc.data();
      const senderName =
        userData.username ||
        userData.email ||
        "Someone special";

      const releasedSnap = await userDoc.ref
          .collection("capsules")
          .where("releaseDate", "<=", admin.firestore.Timestamp.now())
          .limit(20)
          .get();

        console.log("SMS check user:", userDoc.id, "due capsules:", releasedSnap.size);

      for (const capsuleDoc of releasedSnap.docs) {

        const capsule = capsuleDoc.data();
        const recipients = capsule.recipients || [];

        for (const recipient of recipients) {

          let phone = recipient.phone || "";

          if (!phone && recipient.id) {
            const contactSnap = await userDoc.ref
              .collection("trustedContacts")
              .doc(recipient.id)
              .get();

            console.log("SMS contact lookup:", recipient.id, contactSnap.exists, JSON.stringify(contactSnap.data() || {}));
            phone = contactSnap.data()?.phone || "";
          }

          phone = phone.replace(/\D/g, "");

          if (phone.length === 10) {
            phone = `+1${phone}`;
          } else if (phone.length === 11 && phone.startsWith("1")) {
            phone = `+${phone}`;
          }

          if (!phone) {
            console.log("SMS skipped - no phone:", JSON.stringify(recipient));
            continue;
          }

          console.log("SMS sending to:", phone);

          let body =
            `A TYMEFLY memory was released for you from ${senderName}.`;

          if (capsule.message) {
            body += ` Message: ${capsule.message}`;
          }

          if (capsule.mediaUrl) {
            body += ` Open: ${capsule.mediaUrl}`;
          }

          const smsResult = await client.messages.create({
            body,
            from: twilioPhone.value(),
            to: phone,
            });

            console.log("SMS sent SID:", smsResult.sid);
        }

        await capsuleDoc.ref.update({
          smsSent: true,
          smsSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    return null;
  }
);
















