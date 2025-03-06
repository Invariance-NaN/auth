import "dotenv/config"

import express from "express";
import { engine } from "express-handlebars";
import session from "express-session";
import BSSS from "better-sqlite3-session-store";
import bodyParser from "body-parser";

import path from "path";
import { TOTP } from "totp-generator"

import { checkPassword, db, getKeys } from "./data";

const app = express();
const port = process.env.PORT || 3000;

const production = app.get("env") === "production";

// Session
const SESSION_SECRET = process.env.SESSION_SECRET;
if (!SESSION_SECRET) { throw new Error("No SESSION_SECRET env variable!"); }

const SqliteStore = BSSS(session);

declare module "express-session" {
	interface Session {
		loggedIn?: boolean;
	}
}

app.use(
	session({
		cookie: {
			maxAge: 24 * 60 * 60 * 1000,
			secure: production
		},
		store: new SqliteStore({
			client: db,
			expired: {
				clear: true,
				intervalMs: 900000
			}
		}),
		secret: SESSION_SECRET,
		resave: false,
		saveUninitialized: false
	})
);

// Body parser
app.use(bodyParser.urlencoded({ extended: true }));

// Setup handlebars
app.engine("handlebars", engine());
app.set("view engine", "handlebars");
app.set("views", path.join(__dirname, "views"));

// Static files
app.use(express.static(path.join(__dirname, "..", "public")));

// Endpoints
app.get("/", (req, res) => {
	if (!req.session.loggedIn) {
		return res.redirect("/login");
	}

	res.render("pages/index", { title: 'TailwindCSS with Express!' });
});

app.get("/codes", async (req, res) => {
	if (!req.session.loggedIn) { return res.redirect("/login"); }

	const keys = await getKeys();
	const codes = keys.map(({ id, name, key }) => {
		const { otp: code, expires } = TOTP.generate(key);
		return { id, name, code, expires }
	});

	res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify(codes));
});


app.get("/login", (_req, res) => {
	res.render("pages/login", { "password-class": "" });
});


app.post("/login", async (req, res) => {
	if (req.body.password && await checkPassword(req.body.password)) {
		req.session.loggedIn = true;
		return res.redirect("/");
	}

	res.render("pages/login", { "password-class": "border-red-500" });
});


// Start the server
app.listen(port, () => {
	console.log(`Server is running at http://localhost:${port}`);
});
