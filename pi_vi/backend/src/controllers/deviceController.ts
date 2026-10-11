import { Response } from 'express';
import { Types } from 'mongoose';
import { AuthRequest } from '../middlewares/authMiddleware';
import { Device, deviceTypes } from '../models/Device';

const getOwnerId = (req: AuthRequest): string | undefined => {
  const ownerId = req.user?.id;
  return typeof ownerId === 'string' && Types.ObjectId.isValid(ownerId) ? ownerId : undefined;
};

const deviceFields = ['name', 'type', 'description', 'location', 'status', 'state', 'configuration', 'telemetry', 'system'] as const;

export const getDashboard = async (req: AuthRequest, res: Response): Promise<void> => {
  const ownerId = getOwnerId(req);
  if (!ownerId) {
    res.status(401).json({ message: 'Usuário não identificado no token.' });
    return;
  }

  try {
    const filter = { owner: ownerId };
    const [total, online, offline, byType, recentDevices] = await Promise.all([
      Device.countDocuments(filter),
      Device.countDocuments({ ...filter, status: 'online' }),
      Device.countDocuments({ ...filter, status: 'offline' }),
      Device.aggregate<{ _id: string; count: number }>([
        { $match: { owner: new Types.ObjectId(ownerId) } },
        { $group: { _id: '$type', count: { $sum: 1 } } }
      ]),
      Device.find(filter).sort({ updatedAt: -1 }).limit(5).select('name type status location updatedAt').lean()
    ]);

    res.json({
      devices: { total, online, offline, unknown: total - online - offline },
      byType: Object.fromEntries(byType.map(({ _id, count }) => [_id, count])),
      recentDevices
    });
  } catch (error) {
    res.status(500).json({ message: 'Erro ao carregar o dashboard.' });
  }
};

export const listDevices = async (req: AuthRequest, res: Response): Promise<void> => {
  const ownerId = getOwnerId(req);
  if (!ownerId) {
    res.status(401).json({ message: 'Usuário não identificado no token.' });
    return;
  }

  const filter: Record<string, unknown> = { owner: ownerId };
  const { type, status, search } = req.query;
  if (typeof type === 'string') filter.type = type;
  if (typeof status === 'string') filter.status = status;
  if (typeof search === 'string' && search.trim()) {
    filter.name = { $regex: search.trim(), $options: 'i' };
  }

  try {
    const devices = await Device.find(filter).sort({ createdAt: -1 }).lean();
    res.json({ devices });
  } catch (error) {
    res.status(500).json({ message: 'Erro ao listar dispositivos.' });
  }
};

export const createDevice = async (req: AuthRequest, res: Response): Promise<void> => {
  const ownerId = getOwnerId(req);
  if (!ownerId) {
    res.status(401).json({ message: 'Usuário não identificado no token.' });
    return;
  }

  const { name, type } = req.body;
  if (typeof name !== 'string' || !name.trim() || !deviceTypes.includes(type)) {
    res.status(400).json({ message: 'Informe um nome e um tipo de dispositivo válido.', supportedTypes: deviceTypes });
    return;
  }

  const fields: Record<string, unknown> = { owner: ownerId, name: name.trim(), type };
  for (const field of deviceFields) {
    if (field !== 'name' && field !== 'type' && req.body[field] !== undefined) fields[field] = req.body[field];
  }

  try {
    const device = await Device.create(fields);
    res.status(201).json({ device });
  } catch (error) {
    res.status(400).json({ message: 'Não foi possível cadastrar o dispositivo.' });
  }
};

export const getDevice = async (req: AuthRequest, res: Response): Promise<void> => {
  const ownerId = getOwnerId(req);
  if (!ownerId) {
    res.status(401).json({ message: 'Usuário não identificado no token.' });
    return;
  }

  const deviceId = req.params.id;
  if (typeof deviceId !== 'string' || !Types.ObjectId.isValid(deviceId)) {
    res.status(400).json({ message: 'Identificador de dispositivo inválido.' });
    return;
  }

  try {
    const device = await Device.findOne({ _id: deviceId, owner: ownerId }).lean();
    if (!device) {
      res.status(404).json({ message: 'Dispositivo não encontrado.' });
      return;
    }
    res.json({ device });
  } catch (error) {
    res.status(500).json({ message: 'Erro ao carregar o dispositivo.' });
  }
};

export const updateDevice = async (req: AuthRequest, res: Response): Promise<void> => {
  const ownerId = getOwnerId(req);
  if (!ownerId) {
    res.status(401).json({ message: 'Usuário não identificado no token.' });
    return;
  }

  const deviceId = req.params.id;
  if (typeof deviceId !== 'string' || !Types.ObjectId.isValid(deviceId)) {
    res.status(400).json({ message: 'Identificador de dispositivo inválido.' });
    return;
  }

  const updates: Record<string, unknown> = {};
  for (const field of deviceFields) {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  }
  if (typeof updates.name === 'string') updates.name = updates.name.trim();
  if (updates.type !== undefined && !deviceTypes.includes(updates.type as typeof deviceTypes[number])) {
    res.status(400).json({ message: 'Tipo de dispositivo inválido.', supportedTypes: deviceTypes });
    return;
  }

  try {
    const device = await Device.findOneAndUpdate(
      { _id: deviceId, owner: ownerId },
      { $set: updates },
      { new: true, runValidators: true }
    );
    if (!device) {
      res.status(404).json({ message: 'Dispositivo não encontrado.' });
      return;
    }
    res.json({ device });
  } catch (error) {
    res.status(400).json({ message: 'Não foi possível atualizar o dispositivo.' });
  }
};

export const deleteDevice = async (req: AuthRequest, res: Response): Promise<void> => {
  const ownerId = getOwnerId(req);
  if (!ownerId) {
    res.status(401).json({ message: 'Usuário não identificado no token.' });
    return;
  }

  const deviceId = req.params.id;
  if (typeof deviceId !== 'string' || !Types.ObjectId.isValid(deviceId)) {
    res.status(400).json({ message: 'Identificador de dispositivo inválido.' });
    return;
  }

  try {
    const device = await Device.findOneAndDelete({ _id: deviceId, owner: ownerId });
    if (!device) {
      res.status(404).json({ message: 'Dispositivo não encontrado.' });
      return;
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ message: 'Erro ao remover o dispositivo.' });
  }
};