import path from "path";
import sqlite3 from "better-sqlite3";

const args = process.argv.slice(2);

if (args.length !== 1 || args[0].length === 0) { throw new Error("Usage: auth-server <database file>"); }
export const dbPath = path.resolve(args[0]);


export const db = sqlite3(dbPath);
