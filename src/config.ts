const getEnvVar = function(name: string): string {
	const value = process.env[name];
	if (!value) {
		throw new Error(`Enviornment variable ${name} must be set`);
	}
	return value;
}

// TODO: error handling for bad "PORT" values?
export const PORT: number = +getEnvVar("PORT");
export const SESSION_SECRET: string = getEnvVar("SESSION_SECRET");
export const DB_PATH: string = getEnvVar("DB_PATH");
