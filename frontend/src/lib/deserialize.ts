export interface JsonApiResource {
  id: string;
  type: string;
  attributes?: Record<string, unknown>;
  relationships?: Record<string, { data: JsonApiLinkage | JsonApiLinkage[] | null }>;
}

export interface JsonApiLinkage {
  id: string;
  type: string;
}

export interface JsonApiDoc<T = JsonApiResource | JsonApiResource[]> {
  data?: T;
  included?: JsonApiResource[];
  meta?: Record<string, unknown>;
}

export function camelize(key: string): string {
  return key.replace(/_([a-z0-9])/g, (_, char: string) => char.toUpperCase());
}

export function keyFor(type: string, id: string): string {
  return `${type}:${id}`;
}

export function underscore(key: string): string {
  return key.replace(/[A-Z]/g, (char: string) => `_${char.toLowerCase()}`);
}

export function underscoreKeys(attributes: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(attributes)) {
    result[underscore(key)] = value;
  }
  return result;
}

function camelizeValue(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(camelizeValue);
  }
  if (value !== null && typeof value === 'object') {
    const result: Record<string, unknown> = {};
    for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
      result[camelize(key)] = camelizeValue(nested);
    }
    return result;
  }
  return value;
}

function camelizeAttributes(attributes?: Record<string, unknown>): Record<string, unknown> {
  return camelizeValue(attributes ?? {}) as Record<string, unknown>;
}

function buildIncludedMap(included: JsonApiResource[] = []): Map<string, unknown> {
  const raw = new Map<string, JsonApiResource>();
  for (const resource of included) {
    raw.set(keyFor(resource.type, resource.id), resource);
  }

  // Two passes so relationships between included resources also resolve.
  const map = new Map<string, unknown>();
  for (const [key, resource] of raw) {
    map.set(key, { id: resource.id, ...camelizeAttributes(resource.attributes) });
  }
  for (const [key, resource] of raw) {
    map.set(key, deserializeResource(resource, map));
  }
  return map;
}

function resolveLinkage(linkage: JsonApiLinkage, map: Map<string, unknown>): unknown {
  return map.get(keyFor(linkage.type, linkage.id)) ?? { id: linkage.id, type: linkage.type };
}

function resolveRelationship(
  data: JsonApiLinkage | JsonApiLinkage[] | null | undefined,
  map: Map<string, unknown>,
): unknown {
  if (data == null) return null;
  if (Array.isArray(data)) return data.map((linkage) => resolveLinkage(linkage, map));
  return resolveLinkage(data, map);
}

export function deserializeResource(
  resource: JsonApiResource,
  included: Map<string, unknown>,
): Record<string, unknown> {
  const result: Record<string, unknown> = {
    id: resource.id,
    ...camelizeAttributes(resource.attributes),
  };

  for (const [name, relationship] of Object.entries(resource.relationships ?? {})) {
    result[camelize(name)] = resolveRelationship(relationship?.data, included);
  }

  return result;
}

export function deserializeCollection(doc: JsonApiDoc<JsonApiResource[]>): Record<string, unknown>[] {
  const map = buildIncludedMap(doc.included);
  return (doc.data ?? []).map((resource) => deserializeResource(resource, map));
}

function camelizeMeta(meta?: Record<string, unknown>): Record<string, unknown> | undefined {
  if (!meta) return undefined;
  return camelizeValue(meta) as Record<string, unknown>;
}

export function deserializeDoc(
  doc: JsonApiDoc,
): { data: unknown; meta?: Record<string, unknown> } {
  const meta = camelizeMeta(doc.meta);

  if (Array.isArray(doc.data)) {
    return { data: deserializeCollection(doc as JsonApiDoc<JsonApiResource[]>), meta };
  }

  if (doc.data) {
    const map = buildIncludedMap(doc.included);
    return { data: deserializeResource(doc.data as JsonApiResource, map), meta };
  }

  return { data: null, meta };
}
