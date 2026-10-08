const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.pvjljdlsrmxcckfxoijr:stylesync-db-2026@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres'
});

async function run() {
  await client.connect();
  
  // get Test Designer
  const res2 = await client.query(`
    SELECT "Id", "Email", "Name"
    FROM "Users"
    WHERE "Email" = 'test.designer@stylesync.lk'
  `);
  
  if (res2.rows.length > 0) {
    const designerId = res2.rows[0].Id;
    console.log("Test Designer ID:", designerId);
    
    // update latest quote to Test Designer
    await client.query(`
      UPDATE "Quotes"
      SET "DesignerId" = $1
      WHERE "Id" = (
        SELECT "Id" FROM "Quotes" ORDER BY "CreatedAt" DESC LIMIT 1
      )
    `, [designerId]);
    
    // update latest contract to Test Designer
    await client.query(`
      UPDATE "Contracts"
      SET "DesignerId" = $1
      WHERE "Id" = (
        SELECT "Id" FROM "Contracts" ORDER BY "CreatedAt" DESC LIMIT 1
      )
    `, [designerId]);
    
    console.log("Quote and Contract successfully mapped to test.designer@stylesync.lk!");
  } else {
    console.log("Test Designer not found in DB.");
  }
  
  await client.end();
}

run();
