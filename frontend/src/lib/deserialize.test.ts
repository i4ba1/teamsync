import { describe, it, expect } from 'vitest';
import {
  camelize,
  deserializeCollection,
  deserializeDoc,
  deserializeResource,
  keyFor,
} from './deserialize';

describe('camelize', () => {
  it('converts snake_case keys to camelCase', () => {
    expect(camelize('today_stats')).toBe('todayStats');
    expect(camelize('full_name')).toBe('fullName');
    expect(camelize('id')).toBe('id');
    expect(camelize('standup_date')).toBe('standupDate');
  });
});

describe('keyFor', () => {
  it('builds a type:id key', () => {
    expect(keyFor('user', 'u1')).toBe('user:u1');
  });
});

describe('deserializeCollection', () => {
  const doc = {
    data: [
      {
        id: 't1',
        type: 'team',
        attributes: {
          name: 'Demo Team',
          member_count: 3,
          today_stats: { submitted: 1, missed: 0, total: 3 },
        },
        relationships: {
          created_by: { data: { id: 'u1', type: 'user' } },
          members: { data: [{ id: 'u1', type: 'user' }] },
        },
      },
    ],
    included: [
      {
        id: 'u1',
        type: 'user',
        attributes: { first_name: 'Ada', last_name: 'Lovelace', full_name: 'Ada Lovelace' },
      },
    ],
  };

  it('camelizes attributes and preserves id', () => {
    const [team] = deserializeCollection(doc) as any[];
    expect(team.id).toBe('t1');
    expect(team.name).toBe('Demo Team');
    expect(team.memberCount).toBe(3);
    expect(team.todayStats).toEqual({ submitted: 1, missed: 0, total: 3 });
  });

  it('resolves to-one and to-many relationships from included', () => {
    const [team] = deserializeCollection(doc) as any[];
    expect(team.createdBy.fullName).toBe('Ada Lovelace');
    expect(team.createdBy.firstName).toBe('Ada');
    expect(team.members).toHaveLength(1);
    expect(team.members[0].lastName).toBe('Lovelace');
  });

  it('degrades an unresolved relationship to a linkage stub', () => {
    const result = deserializeResource(
      {
        id: 's1',
        type: 'standup',
        attributes: {},
        relationships: { team: { data: { id: 'missing', type: 'team' } } },
      },
      new Map(),
    ) as any;
    expect(result.team).toEqual({ id: 'missing', type: 'team' });
  });

  it('returns an empty array when data is absent', () => {
    expect(deserializeCollection({} as any)).toEqual([]);
  });
});

describe('deserializeDoc', () => {
  it('camelizes meta for collections', () => {
    const result = deserializeDoc({
      data: [],
      meta: { current_page: 2, total_count: 5, next_page: null },
    } as any);
    expect(result.meta).toEqual({ currentPage: 2, totalCount: 5, nextPage: null });
  });

  it('deserializes a single resource', () => {
    const result = deserializeDoc({
      data: { id: 't1', type: 'team', attributes: { name: 'Solo' } },
    } as any) as any;
    expect(result.data.name).toBe('Solo');
  });
});
