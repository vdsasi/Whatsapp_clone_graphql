const express = require("express");
const { graphqlHTTP } = require("express-graphql");
const { buildSchema } = require("graphql");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const cookieParser = require("cookie-parser");
const mongoose = require("mongoose");
const cors = require("cors");
const session = require("express-session");
const MongoStore = require("connect-mongo");
const crypto = require("crypto");
const { ObjectId } = require("mongodb");  
const app = express();
app.use(express.json());
app.use(cookieParser());

// Use a more secure CORS configuration
app.use(
  cors({
    origin: "*", // replace with your Flutter web app's URL
    credentials: true,
  })
);

// Connect to MongoDB
mongoose.connect("mongodb://localhost:27017/whatsapp_clone", {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Session configuration
app.use(
  session({
    secret: process.env.SESSION_SECRET || "your_session_secret",
    resave: false,
    saveUninitialized: false,
    store: MongoStore.create({
      mongoUrl: "mongodb://localhost:27017/whatsapp_clone",
      collectionName: "sessions",
    }),
    cookie: {
      maxAge: 1000 * 60 * 60 * 24, // 1 day
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      httpOnly: true,
    },
  })
);

// Custom CSRF protection middleware
function csrfProtection(req, res, next) {
  if (!req.session) {
    return res.status(500).json({ error: "Session not initialized" });
  }

  if (req.method === "GET") {
    // For GET requests, generate and set a new CSRF token
    const csrfToken = crypto.randomBytes(32).toString("hex");
    req.session.csrfToken = csrfToken;
    req.session.save(() => {
      res.cookie("X-CSRF-Token", csrfToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
      });
      next();
    });
  } else {
    // For non-GET requests, validate the CSRF token
    const csrfToken = req.headers["X-CSRF-Token"];
    if (csrfToken !== req.session.csrfToken) {
      return res.status(403).json({ error: "Invalid CSRF token" });
    }
    next();
  }
}

// Apply CSRF protection to all routes
app.use(csrfProtection);

// User model
const User = mongoose.model("User", {
  name: String,
  email: String,
  password: String,
  contacts: [
    {
      name: String,
      email: String,
      profilePicture: String,
    },
  ],
  callHistory: [
    {
      name: String,
      timestamp: String,
      isVideoCall: Boolean,
      isIncoming: Boolean,
      profilePicture: String,
    },
  ],
  statusUpdates: [
    {
      timestamp: String,
      imageUrl: String,
    },
  ],
  chats: [
    {
      chatId: mongoose.Schema.Types.ObjectId,
      name: String,
      lastMessage: String,
      timestamp: String,
      profilePicture: String,
      messages: [
        {
          text: String,
          isMe: Boolean,
          timestamp: String,
        },
      ],
    },
  ],
});

// GraphQL Schema
const schema = buildSchema(`
  type Contact {
    name: String
    email: String
    profilePicture: String
  }

  type CallHistory {
    name: String
    timestamp: String
    isVideoCall: Boolean
    isIncoming: Boolean
    profilePicture: String
  }

  type StatusUpdate {
    timestamp: String
    imageUrl: String
  }

  type ChatMessage {
    text: String
    isMe: Boolean
    timestamp: String
  }

  type Chat {
    chatId: ID
    name: String
    lastMessage: String
    timestamp: String
    profilePicture: String
    messages: [ChatMessage]
  }

  type User {
    name: String
    email: String
    contacts: [Contact]
    callHistory: [CallHistory]
    statusUpdates: [StatusUpdate]
    chats: [Chat]
  }

  type Query {
    getUser(name: String!): User
    getContacts(name: String!): [Contact]
    getCalls(name: String!): [CallHistory]
    getStatusUpdates(name: String!): [StatusUpdate]
    getChats(name: String!): [Chat]
    getMessages(name: String!, chatId: ID!): [ChatMessage]
  }

  type Mutation {
    addUser(name: String!, email: String!, password: String!): String
    addContact(name: String!, contactName: String!, contactEmail: String!, profilePicture: String): Contact
    addCall(name: String!, callerName: String!, isVideoCall: Boolean!, isIncoming: Boolean!): CallHistory
    addStatusUpdate(name: String!, imageUrl: String!): StatusUpdate
    addChat(name: String!, chatName: String!, profilePicture: String): Chat
    addMessage(name: String!, chatId: ID!, text: String!): ChatMessage
  }
`);

// Resolvers
const root = {
  getUser: async ({ name }) => {
    return await User.findOne({ name });
  },
  getContacts: async ({ name }) => {
    const user = await User.findOne({ name });
    return user.contacts;
  },
  getCalls: async ({ name }) => {
    const user = await User.findOne({ name });
    return user.callHistory;
  },
  getStatusUpdates: async ({ name }) => {
    const user = await User.findOne({ name });
    
    return user.statusUpdates;
  },
  getChats: async ({ name }) => {
    console.log("hitting this getChats thing");
    const user = await User.findOne({ name });

    return user.chats;
  },
  getMessages: async ({ name, chatId }) => {
    console.log("name:", name);
    console.log("chatId:", chatId);

    const user = await User.findOne(
      { name },
      { chats: { $elemMatch: { chatId: new ObjectId(chatId) } } }
    );

    console.log("user chats:", user?.chats);

    if (!user || user.chats.length === 0) {
      console.log("Chat not found");
      return [];
    }

    return user.chats[0].messages || [];
  },

  addUser: async ({ name, email, password }) => {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ name, email, password: hashedPassword });
    await user.save();
    return "User added successfully";
  },
  addContact: async ({ name, contactName, contactEmail, profilePicture }) => {
    const user = await User.findOne({ name });
    const newContact = {
      name: contactName,
      email: contactEmail,
      profilePicture,
    };
    user.contacts.push(newContact);
    await user.save();
    return newContact;
  },
  addCall: async ({ name, callerName, isVideoCall, isIncoming }) => {
    const user = await User.findOne({ name });
    const newCall = {
      name: callerName,
      isVideoCall,
      isIncoming,
      timestamp: new Date().toISOString(),
    };
    user.callHistory.push(newCall);
    await user.save();
    return newCall;
  },
  addStatusUpdate: async ({ name, imageUrl }) => {
    const user = await User.findOne({ name });
    const newStatus = { imageUrl, timestamp: new Date().toISOString() };
    user.statusUpdates.push(newStatus);
    await user.save();
    return newStatus;
  },
  addChat: async ({ name, chatName, profilePicture }) => {
    const user = await User.findOne({ name });
    const newChat = {
      name: chatName,
      profilePicture,
      messages: [],
      timestamp: new Date().toISOString(),
    };
    user.chats.push(newChat);
    await user.save();
    return newChat;
  },
  addMessage: async ({ name, chatId, text }) => {
    const user = await User.findOne({ name });
    const chat = user.chats.id(chatId);
    if (!chat) throw new Error("Chat not found");
    const newMessage = {
      text,
      isMe: true,
      timestamp: new Date().toISOString(),
    };
    chat.messages.push(newMessage);
    chat.lastMessage = text;
    chat.timestamp = newMessage.timestamp;
    await user.save();
    return newMessage;
  },
};

// Middleware to authenticate token and session
function authenticateTokenAndSession(req, res, next) {
  console.log("Checking middleware process");

  const token = req.cookies["token"];
  if (!token) {
    console.log("No token found in cookies");
    return res.status(401).json({ error: "Authentication required" });
  }

  jwt.verify(token, "your_jwt_secret", (err, user) => {
    if (err) {
      console.log("JWT verification failed:", err);
      return res.status(403).json({ error: "Invalid token" });
    }

    console.log("middleware passed sucessfully");
    req.name = user.name;
    next();
  });
}



// GraphQL endpoint with authentication
app.use(
  "/graphql",
  authenticateTokenAndSession,
  graphqlHTTP((req) => ({
    schema: schema,
    rootValue: root,
    graphiql: process.env.NODE_ENV === "development",
    context: { name: req.name },
  }))
);

// Signup route
app.post("/api/signup", async (req, res) => {
  try {
    const { email, password, name } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ email, password: hashedPassword, name });
    await user.save();
    res.status(201).json({ message: "User created successfully" });
  } catch (error) {
    res.status(500).json({ error: "Error creating user" });
  }
});

// Login route
app.post("/api/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ error: "Invalid credentials" });
    }
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ error: "Invalid credentials" });
    }
    const sessionId = crypto.randomBytes(16).toString("hex");
    const token = jwt.sign({ name: user.name, sessionId }, "your_jwt_secret", {
      expiresIn: "1d",
    });
    res.cookie("token", token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 24 * 60 * 60 * 1000, // 1 day
    });

    // Set session
    req.session.name = user.name;
    req.session.sessionId = sessionId;

    // Ensure the session is saved before sending the response
    req.session.save((err) => {
      if (err) {
        console.error("Error saving session:", err);
        return res.status(500).json({ error: "Error saving session" });
      }
      console.log("Session saved successfully");
      console.log("Session data:", req.session);
      res.json({ message: "Logged in successfully", name: user.name });
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ error: "Error logging in" });
  }
});

// Logout route
app.post("/api/logout", (req, res) => {
  res.clearCookie("token");
  req.session.destroy((err) => {
    if (err) {
      return res
        .status(500)
        .json({ error: "Could not log out, please try again" });
    }
    res.json({ message: "Logged out successfully" });
  });
});

// CSRF token route
app.get("/api/csrf-token", (req, res) => {
  if (!req.session.csrfToken) {
    // Generate a new CSRF token if it doesn't exist
    const csrfToken = crypto.randomBytes(32).toString("hex");
    req.session.csrfToken = csrfToken;
    req.session.save(() => {
      res.cookie("X-CSRF-Token", csrfToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
      });
      res.json({ csrfToken });
    });
  } else {
    res.json({ csrfToken: req.session.csrfToken });
  }
});

// Protected route example
app.get("/api/protected", authenticateTokenAndSession, (req, res) => {
  res.json({ message: "This is a protected route", userId: req.userId });
});

const PORT = 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
