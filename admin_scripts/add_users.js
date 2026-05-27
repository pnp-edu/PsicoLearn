const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. RUTA AL ARCHIVO DE CREDENCIALES
// Descárgalo desde: Project Settings -> Service Accounts -> Generate New Private Key
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ ERROR: No se encontró "serviceAccountKey.json" en la carpeta admin_scripts.');
  console.log('👉 Descárgalo desde la consola de Firebase (Project Settings -> Service Accounts).');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 2. LISTA DE USUARIOS A AGREGAR/ACTIVAR
const usersToActivate = [
  'aspirante1@gmail.com',
  'aspirante2@gmail.com',
  // Agrega más emails aquí...
];

async function activateUsers() {
  console.log('🚀 Iniciando activación masiva...');
  
  for (const email of usersToActivate) {
    try {
      const userRef = db.collection('users').doc(email.toLowerCase());
      
      await userRef.set({
        email: email.toLowerCase(),
        active: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        // No enviamos last_device_id para que se auto-registre al primer login
      }, { merge: true });

      console.log(`✅ Usuario activado: ${email}`);
    } catch (error) {
      console.error(`❌ Error con ${email}:`, error.message);
    }
  }

  console.log('\n✨ Proceso finalizado.');
}

activateUsers();
