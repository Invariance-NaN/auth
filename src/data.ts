import sqlite3 from "better-sqlite3";
import { verify } from "argon2";

export const db = sqlite3("data.sqlite");

db.exec(`
	CREATE TABLE IF NOT EXISTS "config" ( "key" varchar NOT NULL PRIMARY KEY, "value" varchar );
	CREATE TABLE IF NOT EXISTS "keys" ( "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar NOT NULL, "key" varchar NOT NULL );
`);

// 	CREATE TABLE IF NOT EXISTS "sessions" ( "session_id" varchar NOT NULL PRIMARY KEY, "expires" integer NOT NULL );

const getKeysStmt = db.prepare("SELECT id, name, key FROM keys");
export const getKeys = async function(): Promise<Array<{ id: number, name: string, key: string }>> {
	return getKeysStmt.all() as Array<{ id: number, name: string, key: string }>;
}

const getDigestStmt = db.prepare("SELECT value FROM config WHERE key = 'password-digest'")
export const checkPassword = async function(password: string): Promise<boolean> {
	const { value: digest } = getDigestStmt.get() as { value: string };
	return verify(digest, password);
}

// const checkSessionStmt = db.prepare("SELECT 1 FROM sessions WHERE session_id = @sessionID AND expires > @now")
// const cleanSesssionsStmt = db.prepare("DELETE FROM sessions WHERE expires <= @now");
// export const checkSession = async function(sessionID: string): Promise<boolean> {
// 	const res = checkSessionStmt.get({ sessionID, now: Date.now() }) as { "1": 1 } | undefined
// 	cleanSesssionsStmt.run({ now: Date.now() });
// 	return !!res && Boolean(res[1]);
// }

// const registerSessionStmt = db.prepare("INSERT INTO sessions (session_id, expires) VALUES (@sessionID, @expires);")
// export const registerSession = async function(expires: Date): Promise<string> {
// 	const sessionID = uuidv4();
// 	registerSessionStmt.run({ sessionID, expires: expires.getTime() })
// 	return sessionID;
// }
