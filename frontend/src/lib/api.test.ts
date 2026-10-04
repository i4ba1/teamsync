import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockClient } = vi.hoisted(() => ({
  mockClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
    interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
    defaults: { baseURL: 'http://localhost:3000/api/v1' },
  },
}));

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => mockClient),
    post: vi.fn(),
  },
}));

import { api } from './api';

beforeEach(() => {
  vi.clearAllMocks();
});

describe('api normalization', () => {
  it('normalizes getTeams to app models', async () => {
    mockClient.get.mockResolvedValueOnce({
      data: {
        data: [{ id: 't1', type: 'team', attributes: { name: 'Demo', member_count: 2 } }],
      },
    });

    const res = await api.getTeams();

    expect(res.data[0].name).toBe('Demo');
    expect((res.data[0] as unknown as { memberCount: number }).memberCount).toBe(2);
  });

  it('normalizes getTodayStandup including standup_items', async () => {
    mockClient.get.mockResolvedValueOnce({
      data: {
        data: {
          id: 's1',
          type: 'standup',
          attributes: { standup_date: '2026-10-04', status: 'draft' },
          relationships: { standup_items: { data: [{ id: 'i1', type: 'standup_item' }] } },
        },
        included: [
          {
            id: 'i1',
            type: 'standup_item',
            attributes: { item_type: 'today', content: 'Work', sort_order: 0 },
          },
        ],
      },
    });

    const res = await api.getTodayStandup('demo-team');

    expect(res.data.status).toBe('draft');
    expect((res.data as unknown as { standupItems: { itemType: string }[] }).standupItems[0].itemType).toBe(
      'today',
    );
  });

  it('normalizes login to a camelCase user with token fields intact', async () => {
    mockClient.post.mockResolvedValueOnce({
      data: {
        data: {
          id: 'u1',
          email: 'a@b.com',
          first_name: 'Ada',
          last_name: 'Lovelace',
          full_name: 'Ada Lovelace',
          token: 't',
          refresh_token: 'r',
          expires_in: 900,
        },
      },
    });

    const res = await api.login({ email: 'a@b.com', password: 'secret123' });

    expect((res.data as unknown as { fullName: string }).fullName).toBe('Ada Lovelace');
    expect((res.data as unknown as { token: string }).token).toBe('t');
    expect((res.data as unknown as { refresh_token: string }).refresh_token).toBe('r');
  });

  it('normalizes standup pagination meta', async () => {
    mockClient.get.mockResolvedValueOnce({
      data: { data: [], meta: { current_page: 1, total_count: 0, total_pages: 0 } },
    });

    const res = await api.getStandups('demo-team');

    expect(res.meta.currentPage).toBe(1);
  });
});
