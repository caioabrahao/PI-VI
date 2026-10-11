import { Document, model, Schema, Types } from 'mongoose';

export const deviceTypes = [
  'smart_led_bulb',
  'smart_plug',
  'smart_switch',
  'raspberry_pi',
  'esp32'
] as const;

export interface IDevice extends Document {
  owner: Types.ObjectId;
  name: string;
  type: typeof deviceTypes[number];
  description?: string;
  location?: string;
  status: 'online' | 'offline' | 'unknown';
  state: Record<string, unknown>;
  configuration: Record<string, unknown>;
  telemetry: Record<string, unknown>;
  system: Record<string, unknown>;
}

const deviceSchema = new Schema<IDevice>({
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  name: { type: String, required: true, trim: true },
  type: { type: String, enum: deviceTypes, required: true },
  description: { type: String, trim: true },
  location: { type: String, trim: true },
  status: { type: String, enum: ['online', 'offline', 'unknown'], default: 'unknown' },
  state: { type: Schema.Types.Mixed, default: {} },
  configuration: { type: Schema.Types.Mixed, default: {} },
  telemetry: { type: Schema.Types.Mixed, default: {} },
  system: { type: Schema.Types.Mixed, default: {} }
}, { timestamps: true });

export const Device = model<IDevice>('Device', deviceSchema);