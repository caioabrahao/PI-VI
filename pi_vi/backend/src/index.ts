import express from 'express';
import dotenv from 'dotenv';
import { connectDB } from './config/database';
import { register, login } from './controllers/authController';
import { authenticateToken, AuthRequest } from './middlewares/authMiddleware';

dotenv.config();

const app = express();
app.use(express.json());

connectDB();

// Rotas públicas
app.post('/api/register', register);
app.post('/api/login', login);

// Rota protegida (exemplo)
app.get('/api/perfil', authenticateToken, (req: AuthRequest, res) => {
  res.json({ message: 'Você acessou uma rota protegida!', user: req.user });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));