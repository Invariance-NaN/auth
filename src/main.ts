import "./config";

import express from "express";
import { engine } from "express-handlebars";
import session from "express-session";
import BSSS from "better-sqlite3-session-store";
import bodyParser from "body-parser";

import path from "path";
import { TOTP } from "totp-generator"

import { checkPassword, db, getKeys } from "./data";
import { PORT, SESSION_SECRET } from "./config";

const app = express();

const production = app.get("env") === "production";


const SQLiteStore = BSSS(session);

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
		store: new SQLiteStore({
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


app.use(bodyParser.urlencoded({ extended: true }));

app.engine("handlebars", engine());
app.set("view engine", "handlebars");
app.set("views", path.join(__dirname, "views"));

app.use(express.static(path.join(__dirname, "..", "public")));

app.get("/", (req, res) => {
	if (!req.session.loggedIn) {
		return res.redirect("/login");
	}

	res.render("pages/index");
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


app.listen(PORT, () => {
	console.log(`Server is running at http://localhost:${PORT}`);
});
