import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models/User';

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { nome, email, senha } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      res.status(400).json({ message: 'E-mail já cadastrado.' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(senha, salt);

    const newUser = await User.create({
      nome,
      email,
      senha: hashedPassword
    });

    res.status(201).json({
      message: 'Usuário registrado com sucesso!',
      user: { id: newUser._id, nome: newUser.nome, email: newUser.email }
    });
  } catch (error) {
    res.status(500).json({ message: 'Erro ao registrar usuário.', error });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, senha } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      res.status(400).json({ message: 'Credenciais inválidas.' });
      return;
    }

    const isMatch = await bcrypt.compare(senha, user.senha);
    if (!isMatch) {
      res.status(400).json({ message: 'Credenciais inválidas.' });
      return;
    }

    const secret = process.env.JWT_SECRET || 'fallback_secret';
    const token = jwt.sign({ id: user._id, email: user.email }, secret, {
      expiresIn: '1h'
    });

    res.status(200).json({
      message: 'Login realizado com sucesso!',
      token
    });
  } catch (error) {
    res.status(500).json({ message: 'Erro ao realizar login.', error });
  }
};