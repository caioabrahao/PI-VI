import mongoose from 'mongoose';

export const connectDB = async (): Promise<void> => {
  try {
    const mongoUri = (globalThis as typeof globalThis & {
      process?: { env?: { MONGO_URI?: string } };
    }).process?.env?.MONGO_URI || '';
    const conn = await mongoose.connect(mongoUri);
    console.log(`MongoDB conectado: ${conn.connection.host}`);
  } catch (error) {
    console.error('Erro ao conectar ao MongoDB:', error);
    (globalThis as typeof globalThis & {
      process?: { exit?: (code: number) => never };
    }).process?.exit?.(1);
  }
};