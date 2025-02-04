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

const app = express();
const port = 3000;
const saltRounds = 6;
env.config();

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

// =========================== User Management ===========================

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

app.listen(port, () => {
  console.log(`Server is running on port ${port}.`);
});
