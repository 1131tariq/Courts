import express from "express";
import morgan from "morgan";
import bodyParser from "body-parser";
import env from "dotenv";
import pg from "pg";
import bcrypt from "bcrypt";
import session from "express-session";
import passport from "passport";
import { Strategy } from "passport-local";
import cors from "cors";
import { WebSocketServer } from "ws";
import http from "http";

const app = express();
const server = http.createServer(app); // Attach WebSocket to existing Express server
const wss = new WebSocketServer({ server });
const port = 3000;
const saltRounds = 6;
env.config();

// Store connected users (socket.id -> userId)
const users = new Map();

wss.on("connection", (ws) => {
  console.log("🔗 New WebSocket connection established");

  ws.on("message", async (message) => {
    try {
      console.log("📥 Received WebSocket message:", message);
      const data = JSON.parse(message);
      const userId = String(data.data?.userId); // ✅ Ensure userId is always a String

      if (data.event === "joinChat" && userId) {
        users.set(userId, ws); // ✅ Store userId as a String
        console.log(`✅ User ${userId} joined WebSocket`);
        console.log("📌 Active WebSocket Users:", Array.from(users.keys())); // ✅ Log stored users
      } else if (data.event === "sendMessage" && userId) {
        console.log(`📤 Message from user ${userId}:`, data.data);

        const { chatId, sender, content, timestamp } = data.data;

        // ✅ Insert message into database
        const insertQuery = `
          INSERT INTO messages (chat_id, sender, content, timestamp)
          VALUES ($1, $2, $3, TO_TIMESTAMP($4))
          RETURNING *;
        `;

        const result = await db.query(insertQuery, [
          chatId,
          sender,
          content,
          timestamp,
        ]);

        console.log("✅ Message saved to DB:", result.rows[0]);

        // ✅ Get chat participants
        const chatQuery = `SELECT participants FROM chats WHERE id = $1;`;
        const chatResult = await db.query(chatQuery, [chatId]);

        if (chatResult.rows.length === 0) {
          console.error("❌ Chat not found!");
          return;
        }

        const participants = chatResult.rows[0].participants.map(String); // ✅ Convert participant IDs to Strings

        // ✅ Broadcast message only to chat participants
        const newMessage = {
          id: result.rows[0].id,
          chatId,
          sender,
          content,
          timestamp,
        };

        broadcastMessageToChat(participants, newMessage);
      } else {
        console.warn("⚠️ Missing or invalid userId in WebSocket message", data);
      }
    } catch (error) {
      console.error("Error processing WebSocket message:", error);
    }
  });

  ws.on("close", () => {
    console.log("❌ WebSocket connection closed");
    users.forEach((value, key) => {
      if (value === ws) {
        users.delete(key);
        console.log(`❌ Removed User ${key} from WebSocket map`);
      }
    });
  });
});

function broadcastMessageToChat(participants, message) {
  console.log(`📡 Broadcasting message to chat ${message.chatId}:`, message);

  let delivered = 0;

  participants.forEach((participantId) => {
    const stringParticipantId = String(participantId);

    if (users.has(stringParticipantId)) {
      const ws = users.get(stringParticipantId);
      if (ws && ws.readyState === ws.OPEN) {
        const outgoingMessage = {
          event: "newMessage",
          data: message,
        };

        console.log(
          `📤 Sending message to user ${stringParticipantId}:`,
          JSON.stringify(outgoingMessage)
        );

        ws.send(JSON.stringify(outgoingMessage));
        delivered++;
        console.log("sent");
      } else {
        console.warn(`⚠️ WebSocket not open for user ${stringParticipantId}`);
      }
    } else {
      console.warn(`⚠️ User ${stringParticipantId} not connected`);
    }
  });

  if (delivered === 0) {
    console.warn("🚨 No active users received the message!");
  }
}

// Database Connection
const db = new pg.Client({
  user: process.env.PG_USER,
  host: process.env.PG_HOST,
  database: process.env.PG_DATABASE,
  password: process.env.PG_PASSWORD,
  port: process.env.PG_PORT,
});
db.connect();

// Middleware
app.use(express.json());
app.use(cors({ origin: "http://localhost:5173", credentials: true }));
app.use(morgan("combined"));
app.use(bodyParser.urlencoded({ extended: true }));

app.use(
  session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { maxAge: 24 * 60 * 60 * 1000 }, // 1 day
  })
);
app.use(passport.initialize());
app.use(passport.session());

// =========================== Authentication Routes ===========================

// Register Route
app.post("/register", async (req, res) => {
  const { email, password } = req.body;

  try {
    if (!email || !password) {
      return res
        .status(400)
        .json({ error: "Email and password are required." });
    }

    // Check if email exists
    const checkResult = await db.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    if (checkResult.rows.length > 0) {
      return res.status(409).json({ error: "Email already in use." });
    }

    // Hash password and store user
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const insertQuery = `
      INSERT INTO users (email, password, created_at, updated_at)
      VALUES ($1, $2, NOW(), NOW())
      RETURNING id, email, first_name, last_name, phone, play_position, marketing_preferences;
    `;
    const result = await db.query(insertQuery, [email, hashedPassword]);
    const user = result.rows[0];

    req.login(user, (err) => {
      if (err) {
        return res
          .status(500)
          .json({ error: "Login failed after registration." });
      }
      res.status(201).json({ message: "Registration successful", user });
    });
  } catch (err) {
    console.error("Registration Error:", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Login Route
app.post("/login", (req, res, next) => {
  passport.authenticate("local", (err, user, info) => {
    if (err) {
      console.error("❌ Authentication Error:", err);
      return res.status(500).json({ error: "Internal Server Error" });
    }
    if (!user) {
      console.warn("❌ Authentication Failed:", info);
      return res.status(401).json({ error: info?.message || "Unauthorized" });
    }

    req.login(user, (err) => {
      if (err) {
        console.error("❌ Login Error:", err);
        return res.status(500).json({ error: "Internal Server Error" });
      }

      const responseUser = {
        id: user.id,
        first_name: user.first_name || "",
        last_name: user.last_name || "",
        email: user.email,
        phone: user.phone || "",
        play_position: user.play_position || "",
        marketing_preferences: user.marketing_preferences || false,
        location: user.location || "",
        matches: user.matches || 0,
        followers: user.followers || 0,
        following: user.following || 0,
        level: user.level || "Beginner",
        bestHand: user.bestHand || "Unknown",
        courtPosition: user.courtPosition || "Not Set",
        matchType: user.matchType || "Casual",
        preferredTime: user.preferredTime || "Anytime",
        playerLevel: user.playerLevel || "Unranked",
        accountType: user.accountType || "Standard", // Added Account Type
      };

      console.log(
        "✅ Sending JSON Response:",
        JSON.stringify({ message: "Login successful", user: responseUser })
      );

      return res.status(200).json({
        message: "Login successful",
        user: responseUser,
      });
    });
  })(req, res, next);
});

// Logout Route
app.get("/logout", (req, res) => {
  req.logout((err) => {
    if (err) {
      return res.status(500).json({ error: "Logout failed" });
    }
    res.status(200).json({ message: "Logout successful" });
  });
});

// Auth Check Route
app.get("/auth/status", (req, res) => {
  if (req.isAuthenticated()) {
    res.status(200).json({ user: req.user });
  } else {
    res.status(401).json({ error: "Not authenticated" });
  }
});

// Update User Profile
app.put("/update/:id", async (req, res) => {
  const userId = req.params.id;
  const {
    first_name,
    last_name,
    email,
    phone,
    date_of_birth,
    gender,
    location,
    password,
  } = req.body;

  try {
    let query = `
          UPDATE users 
          SET first_name = $1, last_name = $2, email = $3, phone = $4, 
              date_of_birth = $5, gender = $6, location = $7, updated_at = NOW()
      `;
    let values = [
      first_name,
      last_name,
      email,
      phone,
      date_of_birth,
      gender,
      location,
    ];

    if (password) {
      const hashedPassword = await bcrypt.hash(password, 10);
      query += `, password = $8 `;
      values.push(hashedPassword);
    }

    query += ` WHERE id = $${values.length + 1} RETURNING *;`;
    values.push(userId);

    const result = await db.query(query, values);
    res
      .status(200)
      .json({ message: "Profile updated successfully", user: result.rows[0] });
  } catch (error) {
    console.error("❌ Error updating profile:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// =========================== User Management =================================

//
app.get("/chats", async (req, res) => {
  try {
    const chats = await db.query(`
      SELECT c.id, c.participants, (
          SELECT jsonb_build_object(
              'id', m.id, 
              'sender', m.sender, 
              'content', m.content, 
              'timestamp', m.timestamp
          )
          FROM messages m 
          WHERE m.chat_id = c.id 
          ORDER BY m.timestamp DESC 
          LIMIT 1
      ) AS lastMessage
      FROM chats c;
    `);

    res.json(chats.rows);
  } catch (error) {
    console.error("Error fetching chats:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

app.get("/chats/:chatId/messages", async (req, res) => {
  try {
    const { chatId } = req.params;
    const result = await db.query(
      `SELECT id, chat_id AS "chatId", sender, content, 
              EXTRACT(EPOCH FROM timestamp) AS "timestamp"
       FROM messages 
       WHERE chat_id = $1 
       ORDER BY timestamp ASC`,
      [chatId]
    );

    // ✅ Ensure `timestamp` is a Double, not a String
    const fixedResult = result.rows.map((message) => ({
      ...message,
      timestamp: parseFloat(message.timestamp), // ✅ Convert to Double
    }));

    console.log(
      "📤 Fixed Messages Response:",
      JSON.stringify(fixedResult, null, 2)
    ); // Debug output

    res.json(fixedResult);
  } catch (error) {
    console.error("Error fetching messages:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Fetch User by ID
app.get("/users/:id", async (req, res) => {
  try {
    const result = await db.query("SELECT * FROM users WHERE id = $1", [
      req.params.id,
    ]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Update User Preferences
app.put("/users/:id", async (req, res) => {
  const { first_name, last_name, phone, play_position, marketing_preferences } =
    req.body;
  try {
    const updateQuery = `
      UPDATE users 
      SET first_name = $1, last_name = $2, phone = $3, play_position = $4, marketing_preferences = $5, updated_at = NOW()
      WHERE id = $6 RETURNING *;
    `;
    const result = await db.query(updateQuery, [
      first_name,
      last_name,
      phone,
      play_position,
      marketing_preferences,
      req.params.id,
    ]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Delete User
app.delete("/users/:id", async (req, res) => {
  try {
    await db.query("DELETE FROM users WHERE id = $1", [req.params.id]);
    res.status(200).json({ message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// =========================== Courts & Bookings Management ======================

// 🏟 1️⃣ Get All Courts
app.get("/api/courts", async (req, res) => {
  try {
    const result = await db.query(`
          SELECT id, name, location, 
          latitude::FLOAT AS latitude, 
          longitude::FLOAT AS longitude, 
          open_time, close_time 
          FROM courts;
      `);

    console.log("Fetched courts from database:", result.rows); // ✅ Debugging

    res.json(result.rows);
  } catch (err) {
    console.error("Error fetching courts:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 📅 2️⃣ Get Available Slots for a Court on a Given Date
app.get("/api/court/:court_id/available-slots", async (req, res) => {
  try {
    const { court_id } = req.params;
    const { date } = req.query;

    console.log(
      "📡 Fetching available slots for court:",
      court_id,
      "Date:",
      date
    );

    // Get court opening & closing time
    const courtResult = await db.query(
      `SELECT open_time, close_time FROM courts WHERE id = $1;`,
      [court_id]
    );
    if (courtResult.rowCount === 0) {
      return res.status(404).json({ error: "Court not found" });
    }

    let open_time = new Date(`${date} ${courtResult.rows[0].open_time}`);
    let close_time = new Date(`${date} ${courtResult.rows[0].close_time}`);

    // ✅ Fix: If closing time is earlier than opening time, move it to the next day
    if (close_time < open_time) {
      close_time.setDate(close_time.getDate() + 1);
    }

    console.log(
      "⏳ Court open:",
      open_time.toISOString(),
      "| Close:",
      close_time.toISOString()
    );

    // Get all booked slots for this court & date
    const bookings = await db.query(
      `SELECT start_time, end_time FROM bookings 
           WHERE court_id = $1 
           AND start_time >= $2 AND start_time < $3
           ORDER BY start_time ASC;`,
      [court_id, open_time.toISOString(), close_time.toISOString()]
    );

    let booked_slots = bookings.rows;
    let available_slots = [];
    let last_end = open_time;
    let idCounter = 1;

    for (let slot of booked_slots) {
      let start_time = new Date(slot.start_time);

      if (last_end < start_time) {
        available_slots.push({
          id: idCounter++,
          start_time: last_end.toISOString(),
          end_time: start_time.toISOString(),
        });
      }
      last_end = new Date(slot.end_time);
    }

    if (last_end < close_time) {
      available_slots.push({
        id: idCounter++,
        start_time: last_end.toISOString(),
        end_time: close_time.toISOString(),
      });
    }

    console.log("✅ Available slots:", available_slots);
    res.json(available_slots);
  } catch (err) {
    console.error("❌ Error fetching available slots:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ 3️⃣ Book a Slot
app.post("/api/book-slot", async (req, res) => {
  try {
    const { court_id, user_id, start_time, duration } = req.body;
    const end_time = new Date(
      new Date(start_time).getTime() + duration * 60000
    );

    // Check if the requested time overlaps with any existing booking
    const conflictCheck = await db.query(
      `SELECT * FROM bookings 
           WHERE court_id = $1 
           AND (start_time < $3 AND end_time > $2);`,
      [court_id, start_time, end_time]
    );

    if (conflictCheck.rowCount > 0) {
      return res.status(400).json({ error: "Time slot is already booked." });
    }

    // Insert the new booking
    const result = await db.query(
      `INSERT INTO bookings (court_id, user_id, start_time, end_time)
           VALUES ($1, $2, $3, $4) RETURNING *;`,
      [court_id, user_id, start_time, end_time]
    );

    res.json({ message: "Booking confirmed", booking: result.rows[0] });
  } catch (err) {
    console.error("Error booking slot:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// 🚨 4️⃣ Cancel a Booking
app.delete("/api/cancel-booking/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      `DELETE FROM bookings WHERE id = $1 RETURNING *;`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Booking not found" });
    }

    res.json({ message: "Booking canceled", booking: result.rows[0] });
  } catch (err) {
    console.error("Error canceling booking:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// =========================== Passport Local Strategy ===========================

passport.use(
  "local",
  new Strategy({ usernameField: "email" }, async (email, password, done) => {
    console.log("🚀 Passport Local Strategy Triggered for:", email); // Debugging

    try {
      const result = await db.query("SELECT * FROM users WHERE email = $1", [
        email,
      ]);
      if (result.rows.length > 0) {
        const user = result.rows[0];
        console.log("✅ User found:", user);

        bcrypt.compare(password, user.password, (err, isMatch) => {
          if (err) return done(err);
          if (isMatch) {
            console.log("🔐 Password matched, authenticating user...");
            return done(null, user);
          }
          console.log("❌ Incorrect password");
          return done(null, false, { message: "Invalid credentials" });
        });
      } else {
        console.log("❌ User not found in database.");
        return done(null, false, { message: "User not found" });
      }
    } catch (err) {
      console.error("⚠️ Error in Local Strategy:", err);
      return done(err);
    }
  })
);

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser((user, cb) => {
  cb(null, user);
});

// =========================== Start Server ===========================

server.listen(port, () => {
  console.log(`🚀 Server running on port ${port}`);
});
