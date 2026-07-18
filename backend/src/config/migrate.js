const fs = require('fs');
const path = require('path');
const { pool } = require('./database');

async function runMigrations() {
    console.log('Running database migrations...');

    const migrationsDir = path.join(__dirname, '../../migrations');
    const files = fs.readdirSync(migrationsDir)
        .filter(f => f.endsWith('.sql'))
        .sort();

    for (const file of files) {
        console.log(`Running migration: ${file}`);
        const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');
        try {
            await pool.query(sql);
            console.log(`Migration ${file} completed successfully`);
        } catch (err) {
            console.error(`Migration ${file} failed:`, err.message);
            throw err;
        }
    }

    console.log('All migrations completed');
    await pool.end();
}

runMigrations().catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
});
