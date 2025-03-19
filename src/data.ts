import sqlite3 from "better-sqlite3";
import { verify } from "argon2";
import { dbPath } from "./config";

export const db = sqlite3(dbPath);

db.exec(`
	CREATE TABLE IF NOT EXISTS "config" ( "key" varchar NOT NULL PRIMARY KEY, "value" varchar );
	CREATE TABLE IF NOT EXISTS "keys" ( "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar NOT NULL, "key" varchar NOT NULL );
`);

const getKeysStmt = db.prepare("SELECT id, name, key FROM keys");
export const getKeys = async function(): Promise<Array<{ id: number, name: string, key: string }>> {
	return getKeysStmt.all() as Array<{ id: number, name: string, key: string }>;
}

const getDigestStmt = db.prepare("SELECT value FROM config WHERE key = 'password-digest'")
export const checkPassword = async function(password: string): Promise<boolean> {
	const { value: digest } = getDigestStmt.get() as { value: string };
	return verify(digest, password);
}
