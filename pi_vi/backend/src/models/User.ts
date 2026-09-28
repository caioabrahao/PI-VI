import { Schema, model, Document } from 'mongoose';

export interface IUser extends Document {
  nome: string;
  email: string;
  senha: string;
}

const userSchema = new Schema<IUser>({
  nome: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  senha: { type: String, required: true },
}, { timestamps: true });

export const User = model<IUser>('User', userSchema);