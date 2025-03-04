const express = require('express');
const fs = require('fs').promises;
const cors = require('cors');
const { exec } = require('child_process');
const path = require('path');
const app = express();

// Gunakan port yang disediakan InfinityFree
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public')); // Untuk serving static files

// Ubah path sesuai struktur InfinityFree
const CONFIG_PATH = path.join(__dirname, 'data/config.json');

// Middleware autentikasi sederhana
const authMiddleware = (req, res, next) => {
    const token = req.headers.authorization;
    if (!token) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    // Verifikasi token (implementasi yang lebih aman diperlukan untuk produksi)
    next();
};

// GET products
app.get('/api/products', async (req, res) => {
    try {
        const data = await fs.readFile(CONFIG_PATH, 'utf8');
        const config = JSON.parse(data);
        res.json(config.products);
    } catch (error) {
        res.status(500).json({ error: 'Gagal membaca data produk' });
    }
});

// POST new product
app.post('/api/products', authMiddleware, async (req, res) => {
    try {
        const { id, name, image, link } = req.body;
        const data = await fs.readFile(CONFIG_PATH, 'utf8');
        const config = JSON.parse(data);
        
        // Cek duplikasi ID
        if (config.products.some(p => p.id === id)) {
            return res.status(400).json({ error: 'ID produk sudah ada' });
        }

        config.products.push({ id, name, image, link });
        await fs.writeFile(CONFIG_PATH, JSON.stringify(config, null, 4));
        
        // Git commit dan push
        await gitCommitAndPush('Tambah produk baru');
        
        res.json({ message: 'Produk berhasil ditambahkan' });
    } catch (error) {
        res.status(500).json({ error: 'Gagal menambah produk' });
    }
});

// DELETE product
app.delete('/api/products/:id', authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const data = await fs.readFile(CONFIG_PATH, 'utf8');
        const config = JSON.parse(data);
        
        const index = config.products.findIndex(p => p.id === id);
        if (index === -1) {
            return res.status(404).json({ error: 'Produk tidak ditemukan' });
        }

        config.products.splice(index, 1);
        await fs.writeFile(CONFIG_PATH, JSON.stringify(config, null, 4));
        
        // Git commit dan push
        await gitCommitAndPush('Hapus produk');
        
        res.json({ message: 'Produk berhasil dihapus' });
    } catch (error) {
        res.status(500).json({ error: 'Gagal menghapus produk' });
    }
});

// GitHub sync
app.post('/api/sync', authMiddleware, async (req, res) => {
    try {
        await gitPull();
        res.json({ message: 'Sinkronisasi berhasil' });
    } catch (error) {
        res.status(500).json({ error: 'Gagal sinkronisasi dengan GitHub' });
    }
});

// Endpoint untuk update config.json
app.post('/api/update-config', authMiddleware, async (req, res) => {
    try {
        const { products } = req.body;
        const config = { products };
        await fs.writeFile(CONFIG_PATH, JSON.stringify(config, null, 4));
        res.json({ message: 'Konfigurasi berhasil diupdate' });
    } catch (error) {
        res.status(500).json({ error: 'Gagal update konfigurasi' });
    }
});

// Fungsi helper untuk git operations
async function gitCommitAndPush(message) {
    return new Promise((resolve, reject) => {
        exec(`git add . && git commit -m "${message}" && git push`, (error) => {
            if (error) reject(error);
            else resolve();
        });
    });
}

async function gitPull() {
    return new Promise((resolve, reject) => {
        exec('git pull', (error) => {
            if (error) reject(error);
            else resolve();
        });
    });
}

app.listen(port, () => {
    console.log(`Server berjalan di http://localhost:${port}`);
}); 