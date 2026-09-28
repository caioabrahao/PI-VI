import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  user?: any;
}

export const authenticateToken = (req: AuthRequest, res: Response, next: NextFunction): void => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Exige o formato "Bearer TOKEN"

  if (!token) {
    res.status(401).json({ message: 'Acesso negado. Token não fornecido.' });
    return;
  }

  try {
    const secret = process.env.JWT_SECRET || 'fallback_secret';
    const verified = jwt.verify(token, secret);
    req.user = verified;
    next();
  } catch (error) {
    res.status(403).json({ message: 'Token inválido ou expirado.' });
  }
};